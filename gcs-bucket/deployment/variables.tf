variable "service_id" {
  type        = string
  description = "nullplatform service id; labels the bucket."
}

variable "bucket_name" {
  type        = string
  description = "Globally unique bucket name, derived once by build_context and then pinned."
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]{1,61}[a-z0-9]$", var.bucket_name)) && !startswith(var.bucket_name, "goog")
    error_message = "bucket_name must be 3-63 lowercase letters, digits, - or _, start and end alphanumeric, and not start with goog."
  }
}

variable "project_id" {
  type = string
}

variable "location" {
  type        = string
  description = "A GCP region (us-east1) or multi-region (US)."
}

variable "storage_class" {
  type    = string
  default = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class must be STANDARD, NEARLINE, COLDLINE or ARCHIVE."
  }
}

variable "versioning" {
  type    = bool
  default = false
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Let a delete remove a bucket that still has objects. Off by default: a delete then fails instead of dropping data."
}

variable "labels" {
  type    = map(string)
  default = {}
}
