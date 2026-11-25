variable "project_id" {
  type        = string
  description = "Project the buckets are created in."
}

variable "agent_namespace" {
  type        = string
  default     = "nullplatform-tools"
  description = "Namespace of the agent's Kubernetes service account."
}

variable "agent_service_account" {
  type        = string
  default     = "nullplatform-agent"
  description = "Kubernetes service account the worker runs as."
}

variable "grant_tfstate_access" {
  type        = bool
  default     = true
  description = "Grant the worker object access on tfstate_bucket. Turn it off when another service install already grants the same principal the same role on that bucket: two owners of one binding means removing either install revokes it for both."
}

variable "tfstate_bucket" {
  type        = string
  description = "EXISTING bucket for the service's OpenTofu state. Shared with other services; this module only grants object access on it."
}
