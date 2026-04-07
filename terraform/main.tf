# Latest gitlab-base image (used as fallback when gitlab_base_image variable is not set)
data "google_compute_image" "gitlab_base" {
  family  = "gitlab-base"
  project = var.project_id
}

locals {
  image = var.gitlab_base_image != "" ? "projects/${var.project_id}/global/images/${var.gitlab_base_image}" : data.google_compute_image.gitlab_base.self_link
}

# Static external IP
resource "google_compute_address" "gitlab" {
  name   = "gitlab-ip"
  region = var.region
}

# 50GB persistent data disk
resource "google_compute_disk" "data" {
  name = "gitlab-data"
  type = "pd-standard"
  zone = var.zone
  size = 50

  lifecycle {
    prevent_destroy = false
  }
}

# Firewall: allow SSH, HTTP, HTTPS
resource "google_compute_firewall" "gitlab" {
  name    = "gitlab-allow-ingress"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "2222"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitlab"]
}

# VM instance
resource "google_compute_instance" "gitlab" {
  name         = "gitlab"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["gitlab"]

  boot_disk {
    initialize_params {
      image = local.image
      size  = 10
      type  = "pd-balanced"
    }
  }

  attached_disk {
    source      = google_compute_disk.data.self_link
    device_name = "gitlab-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.gitlab.address
    }
  }

  metadata = {
    startup-script = templatefile("${path.module}/templates/startup.sh.tpl", {
      domain_name = var.domain_name
      acme_email  = var.acme_email
    })
    enable-oslogin = "TRUE"
  }
}

# DNS A record: gitlab.hannesalbeiro.com → static IP
resource "google_dns_record_set" "gitlab" {
  name         = "gitlab.${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone_name
  rrdatas      = [google_compute_address.gitlab.address]
}

# Optional: daily snapshot policy on data disk
resource "google_compute_resource_policy" "snapshots" {
  count   = var.enable_snapshots ? 1 : 0
  name    = "gitlab-data-snapshots"
  region  = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "02:00"
      }
    }
    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "snapshots" {
  count   = var.enable_snapshots ? 1 : 0
  name    = google_compute_resource_policy.snapshots[0].name
  disk    = google_compute_disk.data.name
  zone    = var.zone
}
