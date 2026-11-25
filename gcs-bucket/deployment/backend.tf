terraform {
  # Partial configuration: build_context writes bucket and prefix to backend.hcl.
  backend "gcs" {}
}
