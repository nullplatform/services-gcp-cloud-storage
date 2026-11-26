# The link grants a role on this bucket to the linked app's Kubernetes service
# account in the link's environment, np-<application id>-<environment>, through
# Workload Identity: no Google service account and no key. The app's Google
# client libraries pick the identity up on their own. The scopes create that
# service account when they run with IAM.MODE gke, and every scope of the app in
# that environment runs as it. The binding may precede it: GCP accepts a
# principal that does not exist yet, and access starts when the scopes use it.

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

# With a path_prefix the role holds only for objects under it, and listing
# only when the request asks for that prefix (objectListPrefix): a list of the
# whole bucket is denied. Without it, the role covers the whole bucket.
locals {
  prefix_condition = var.path_prefix == "" ? null : join(" || ", [
    "resource.name.startsWith('projects/_/buckets/${var.bucket_name}/objects/${var.path_prefix}')",
    "(resource.type == 'storage.googleapis.com/Bucket' && api.getAttribute('storage.googleapis.com/objectListPrefix', '').startsWith('${var.path_prefix}'))",
  ])
}

resource "google_storage_bucket_iam_member" "link" {
  for_each = local.principals

  bucket = var.bucket_name
  role   = local.roles[var.access_level]
  member = each.value

  dynamic "condition" {
    for_each = local.prefix_condition == null ? [] : [local.prefix_condition]
    content {
      title       = "nullplatform-path-prefix"
      description = "Objects under ${var.path_prefix} only."
      expression  = condition.value
    }
  }
}
