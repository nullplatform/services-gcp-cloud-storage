# Uniform bucket-level access (IAM only, no object ACLs). Public access
# prevention is enforced by default, so no link or object can make the bucket
# public; "inherited" defers to the project or organization policy.
resource "google_storage_bucket" "this" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true
  public_access_prevention    = var.public_access_prevention

  versioning {
    enabled = var.versioning
  }

  # The location is fixed at creation; a later change in the configured
  # region must not replace (empty) an existing bucket.
  lifecycle {
    ignore_changes = [location]
  }

  labels = merge(var.labels, {
    managed-by              = "nullplatform"
    nullplatform-service-id = lower(var.service_id)
  })
}
