terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Credentials come from Application Default Credentials: in the worker, the
# agent's Kubernetes service account through Workload Identity.
provider "google" {
  project = var.project_id
}
