variable "project_id" {
  type        = string
  description = "Project of the bucket and of the GKE cluster's Workload Identity pool (<project_id>.svc.id.goog)."
}

variable "bucket_name" {
  type = string
}

variable "access_level" {
  type    = string
  default = "read-write"
  validation {
    condition     = contains(["read", "write", "read-write"], var.access_level)
    error_message = "access_level must be read, write or read-write."
  }
}

variable "workload_identities" {
  type = list(object({
    namespace       = string
    service_account = string
  }))
  default     = []
  description = "Kubernetes service accounts of the linked app's scopes (one per scope, IAM.MODE gke). Empty on unlink: destroy works from the state."
}
