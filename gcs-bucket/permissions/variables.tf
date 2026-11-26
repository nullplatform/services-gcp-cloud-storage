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
  description = "Kubernetes service account of the linked app in the link's environment (np-<application id>-<environment>, created by the scopes with IAM.MODE gke). Empty on unlink: destroy works from the state."
}

variable "path_prefix" {
  type        = string
  default     = ""
  description = "Limit the role to objects whose name starts with this prefix (e.g. uploads/). Empty: the whole bucket."
  validation {
    condition     = var.path_prefix == "" || (can(regex("^[A-Za-z0-9._-][A-Za-z0-9._/-]{0,511}$", var.path_prefix)) && !strcontains(var.path_prefix, ".."))
    error_message = "path_prefix must be up to 512 letters, digits, '.', '_', '-' or '/', not start with '/' and not contain '..'."
  }
}
