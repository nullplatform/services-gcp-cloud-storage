# Roles the worker needs, granted to the agent's Kubernetes service account
# through Workload Identity (no Google service account in between).

data "google_project" "this" {
  project_id = var.project_id
}

locals {
  worker_principal = format(
    "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s",
    data.google_project.this.number, var.project_id, var.agent_namespace, var.agent_service_account,
  )
}

# Bucket creation is checked against the project, so it cannot be limited by
# name: a custom role carries only create and list.
resource "google_project_iam_custom_role" "bucket_creator" {
  project     = var.project_id
  role_id     = "nullplatformGcsBucketCreator"
  title       = "nullplatform GCS bucket creator"
  description = "Create and list buckets; everything else is granted only on np-gcs-* buckets."
  permissions = ["storage.buckets.create", "storage.buckets.list"]
}

resource "google_project_iam_member" "bucket_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.bucket_creator.name
  member  = local.worker_principal
}

# Manage, grant on and delete only the buckets this service names (np-gcs-*),
# so the worker can neither open nor drop the tfstate bucket or a bucket of
# another nullplatform service. Keep the tfstate bucket outside that prefix.
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = local.worker_principal

  condition {
    title      = "nullplatform-gcs-buckets"
    expression = "resource.name.startsWith('projects/_/buckets/np-gcs-')"
  }
}

# The tfstate bucket is shared with other services: objects only under this
# service's prefix (gcs-bucket/), plus the bucket itself so the backend can list.
resource "google_storage_bucket_iam_member" "tfstate" {
  count  = var.grant_tfstate_access ? 1 : 0
  bucket = var.tfstate_bucket
  role   = "roles/storage.objectAdmin"
  member = local.worker_principal

  condition {
    title       = "nullplatform-gcs-bucket-state"
    description = "Only this service's state, under gcs-bucket/."
    expression  = "resource.type == 'storage.googleapis.com/Bucket' || resource.name.startsWith('projects/_/buckets/${var.tfstate_bucket}/objects/gcs-bucket/')"
  }
}
