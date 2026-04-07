variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "project-84ddd43d-e408-4cb9-8cb"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "GCP zone for VM and data disk"
  type        = string
  default     = "europe-west3-c"
}

variable "domain_name" {
  description = "Root domain (e.g. hannesalbeiro.com)"
  type        = string
  default     = "hannesalbeiro.com"
}

variable "dns_zone_name" {
  description = "Cloud DNS managed zone name"
  type        = string
  default     = "hannesalbeiro-com"
}

variable "acme_email" {
  description = "Email for Let's Encrypt registration"
  type        = string
  default     = "johannes.reichhardt@gmail.com"
}

variable "enable_snapshots" {
  description = "Enable daily disk snapshot schedule (7-day retention)"
  type        = bool
  default     = false
}
