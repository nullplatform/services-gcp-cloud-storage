# The link grants a role on this bucket to the Kubernetes service account of
# each scope of the linked app, through Workload Identity: no Google service
# account and no key. The app's Google client libraries pick the identity up on
# their own. The scopes create those service accounts (<prefix>-<scope id>,
# labeled scope_id) when they run with IAM.MODE gke, so only the linked app
# reaches the bucket. build_permissions_context finds them.

data "google_storage_bucket" "this" {
  name = var.bucket_name
}

locals {
  roles = {
    "read"       = "roles/storage.objectViewer"
    "write"      = "roles/storage.objectCreator"
    "read-write" = "roles/storage.objectUser"
  }

  principals = {
    for wi in var.workload_identities : "${wi.namespace}/${wi.service_account}" => format(
      "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s",
      data.google_storage_bucket.this.project_number, var.project_id, wi.namespace, wi.service_account,
    )
  }
}

resource "google_storage_bucket_iam_member" "link" {
  for_each = local.principals

  bucket = var.bucket_name
  role   = local.roles[var.access_level]
  member = each.value
}
