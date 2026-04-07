output "static_ip" {
  description = "Static external IP of the GitLab VM"
  value       = google_compute_address.gitlab.address
}

output "gitlab_url" {
  description = "GitLab URL"
  value       = "https://gitlab.${var.domain_name}"
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh jre@${google_compute_address.gitlab.address}"
}
