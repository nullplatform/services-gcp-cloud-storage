terraform {
  # Partial configuration: build_permissions_context writes bucket and prefix to backend.hcl.
  backend "gcs" {}
}
