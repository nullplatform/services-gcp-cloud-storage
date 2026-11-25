# GCP Cloud Storage Bucket (nullplatform service)

A private Cloud Storage bucket per service, and access to it per link.

- **Service** (`create`, `update`, `delete`): a bucket with uniform bucket-level access and public access prevention enforced. The name is derived once from the service name and id and then pinned. A delete fails while the bucket holds objects, unless `force_destroy` is on.
- **Link:** not in v0.1.0. Access per app (a Kubernetes service account per scope, through Workload Identity) comes in v0.2.0.

## Identity model
The worker runs as the agent's Kubernetes service account through Workload Identity, with no keys. v0.1.0 has no link, so no app gets access to the bucket through the platform yet.

## Install
- `specs/requirements/gcp`: roles for the agent's Kubernetes service account (Workload Identity): `storage.admin` limited to `np-*` buckets, plus a custom role to create and list buckets; no service account roles. Object access on the tfstate bucket, unless another install already grants it (`grant_tfstate_access = false`).
- Worker image: `Dockerfile` (`NP_PACKAGE_NAME=gcp-cloud-storage-bucket`).
- Published as the package `np-gcp-cloud-storage-bucket` (specification "GCP Cloud Storage Bucket") by `gcs-bucket/publish` on every release; install it with tofu-modules `nullplatform/service_package_installation`.

## Placement
`project_id`, `location` and `tfstate_bucket` resolve from `values.yaml`, then the cloud-providers provider (`.project.id`, `.services.region`, `.services.tfstate.bucket`), then the worker environment (`SERVICES_GCP_PROJECT`/`GOOGLE_CLOUD_PROJECT`, `SERVICES_GCP_REGION`, `SERVICES_TFSTATE_BUCKET`). State lives under `gcs-bucket/<service_id>/`.
