terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  backend "gcs" {
    bucket = "project-84ddd43d-e408-4cb9-8cb-k3s-tf-state"
    prefix = "terraform/state/gitlab"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
