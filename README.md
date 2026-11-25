# GCP Cloud Storage Bucket (nullplatform service)

A private Cloud Storage bucket per service, and access to it per app through a link.

- **Service** (`create`, `update`, `delete`): a bucket with uniform bucket-level access and public access prevention enforced. The name is derived once from the service name and id and then pinned. A delete fails while the bucket holds objects, unless `force_destroy` is on.
- **Link** `connect` (`link`, `link-update`, `unlink`): grants a role on this bucket only to the Kubernetes service account of each scope of the linked app, through Workload Identity. `access_level`: `read` (`roles/storage.objectViewer`), `write` (`roles/storage.objectCreator`) or `read-write` (`roles/storage.objectUser`, the default). The app gets the bucket name from the service (`GCS_BUCKET_NAME`, `GCS_PROJECT_ID`); the link exports nothing and creates no key.

## Identity model
The worker runs as the agent's Kubernetes service account through Workload Identity, with no keys.

Linked apps get access as their own scopes, so only the linked app reaches the bucket. This **requires the scopes to run with `IAM.ENABLED: true` and `IAM.MODE: gke`** ([nullplatform/scopes](https://github.com/nullplatform/scopes), Kubernetes scope): each scope then runs as its own Kubernetes service account, `<IAM.PREFIX>-<scope id>`, labeled `nullplatform=true` and `scope_id=<scope id>`, in the scope's namespace. The link grants the role to `principal://iam.googleapis.com/projects/<project number>/locations/global/workloadIdentityPools/<project id>.svc.id.goog/subject/ns/<namespace>/sa/<service account>` for each of them.

How the link finds them (`scripts/resolve_workload_identities`): it lists the app's scopes (`np scope list`), then the service accounts labeled `nullplatform=true` across the cluster (`kubectl`), and keeps, per scope, the one labeled with its `scope_id` whose name ends in `-<scope id>`, in a trusted namespace: `nullplatform`, one labeled `nullplatform=true`, or one listed in `values.yaml` `app_k8s_namespaces` (never `default` or `kube-*`). Looking them up, rather than rebuilding the name, follows `IAM.PREFIX` and namespace patterns the scopes render, without asking AWS or copying the scopes' configuration here.

- **Without `IAM.MODE: gke`** no scope has its own service account, and the link fails with an error that says so. A scope that has none yet (still being created) gets no access, with a warning, while the other scopes do.
- **Scopes created after the link:** update the link (`link-update` looks the scopes up again and reapplies, which also revokes deleted scopes).
- **Unlink** revokes every binding from the link's own state (`gcs-bucket/<service_id>/links/<link_id>`), without looking at the cluster.
- The cluster's Workload Identity pool must be the bucket's project (`<project id>.svc.id.goog`).

**Workload Identity sameness:** the grant goes to `ns/<namespace>/sa/<service account>` in the project's pool (`<project>.svc.id.goog`), which every GKE cluster with Workload Identity in that project shares. A pod with the same namespace and service account name in another cluster of the project gets the same access. Keep one cluster per project, or one trusted set of clusters, when you use this link.

## Install
- `specs/requirements/gcp`: roles for the agent's Kubernetes service account (Workload Identity): `storage.admin` limited to `np-gcs-*` buckets (keep the tfstate bucket outside that prefix), plus a custom role to create and list buckets; no service account roles (the link grants on the bucket, which `storage.admin` on `np-gcs-*` covers). Object access on the tfstate bucket only under `gcs-bucket/`, unless another install already grants it (`grant_tfstate_access = false`; then that grant applies, as the worker shares the agent's identity).
- Kubernetes, for the link: the agent's Kubernetes service account needs cluster-wide `list` on `serviceaccounts` and `namespaces`.
- Worker image: `Dockerfile` (`NP_PACKAGE_NAME=gcp-cloud-storage-bucket`), with `tofu` and `kubectl`.
- Published as the package `np-gcp-cloud-storage-bucket` (specification "GCP Cloud Storage Bucket") by `gcs-bucket/publish` on every release; install it with tofu-modules `nullplatform/service_package_installation`.

## Placement
`project_id`, `location` and `tfstate_bucket` resolve from `values.yaml`, then the cloud-providers provider (`.project.id`, `.services.region`, `.services.tfstate.bucket`), then the worker environment (`SERVICES_GCP_PROJECT`/`GOOGLE_CLOUD_PROJECT`, `SERVICES_GCP_REGION`, `SERVICES_TFSTATE_BUCKET`). State lives under `gcs-bucket/<service_id>/`: the bucket's in `deployment`, each link's in `links/<link_id>`.

## Run locally as a package

`np package run` runs this service on your machine the way production does: a
local controlplane-agent that registers with the platform, spawns the worker
image built from this repo, and hands it every action routed to it. No cluster,
no publish. The two tasks in `mise.toml` are the whole contract with the CLI:

| Command | Runs | Does |
|---|---|---|
| `np package build --image` | `mise run build:image` | Builds `gcp-cloud-storage-worker:dev` |
| `np package run` | `mise run run` | Builds the image, then starts the local agent |

Prerequisites: **Docker** with host networking (Linux as is; on Docker Desktop
enable *host networking*), **[mise](https://mise.jdx.dev)** (`mise trust` once
here), an **`NP_API_KEY`** for the agent to register with, and `np` from the
**alpha** channel, which carries `np package run`:

```bash
curl -fsSL https://cli.nullplatform.com/install.sh | VERSION=alpha sh   # ~/.local/bin/np
np package run --help                                                   # must list --no-forward-env
```

```bash
export NP_API_KEY=...
eval "$(aws configure export-credentials --format env)"   # cloud credentials as variables
np package run --log-level DEBUG                          # Ctrl+C to stop
```

The agent is tagged `package:gcp-cloud-storage-bucket` and `local:<your user>`. It receives an
action only when the service's notification channel selects those tags, so
point a channel at `local:<your user>` to route work to your machine.

> **Tags decide who gets the work.** Never start a local agent with tags a
> production channel selects: it would receive production actions.

`np package run` forwards your shell's environment to the agent container,
minus what describes your machine (`PATH`, `HOME`, `DOCKER_*`, `KUBECONFIG`,
`AWS_PROFILE` and the other file-pointing AWS variables), and the `run` task
passes the same variables to the worker through an `NP_WORKER_RULES` entry.
Every secret in your shell crosses too, and is readable with `docker inspect`;
pass `--no-forward-env` to forward nothing.

| Variable | Default | Purpose |
|---|---|---|
| `NP_API_KEY` | required | The key the agent registers with (`--api-key` also sets it) |
| `NP_LOG_LEVEL` | `INFO` | Agent log level (`--log-level` also sets it) |
| `NP_PACKAGE_SLUG` | `gcp-cloud-storage-bucket` | The slug in the `package:<slug>` tag, when published under another slug |
| `NP_LOCAL_USER` | `$USER` | The value of the `local:<user>` tag |
| `NP_AGENT_IMAGE` | `controlplane-agent:latest` | The agent image; needs worker rules (0.11.1+) |

The local run never changes what the platform runs. To ship the change, merge
it: the release publishes the image and registers the artifact.

## CI

| Workflow | When | What |
|---|---|---|
| branch-validation | PR | branch named `feat/…`, `fix/…`, `chore/…` |
| conventional-commit | PR | commit messages (release-please reads them) |
| shellcheck | PR | every bash script |
| trivy | PR | IaC misconfiguration and image scan, to the Security tab |
| beta | PR (opened, push, reopened) | publish-test-image-oci: pushes `beta/<image>:test-<branch>-<short sha>` and registers it as a nullplatform artifact |
| release | push to `main` | release-please → build and push `vX.Y.Z` and `latest` to ECR Public → nullplatform artifact → GitHub release |
| auto-merge-release | after release | merges the release PR |
| dependabot | daily / weekly | base image and shared workflow bumps |

## Image tags

| Image | Moved by | Use it to |
|---|---|---|
| `agent-plugins/services/<name>:vX.Y.Z` | its release, once | pin an exact version |
| `agent-plugins/services/<name>:latest` | each release | follow the last released version |
| `beta/agent-plugins/services/<name>:test-<branch>-<short sha>` | each push to a pull request of this repository | deploy a change to a test scope before merging it |

Beta images live in a separate repository that the beta role can write and the production role cannot, so a beta can never overwrite a released image. Pull requests from this repository can assume the beta role (fork and bot pull requests are skipped), and the tag carries the commit SHA, so two pull requests never overwrite each other by accident. Nothing deletes beta tags: they are ephemeral by convention. Each beta is also registered as its own nullplatform oci_image artifact (the `beta/` repository, under `NP_ARTIFACT_NRN`), separate from the release artifact, so it can be deployed to a test scope from the platform.

## Publishing

Set in this repository:

| Name | Kind | Value |
|---|---|---|
| `AWS_ROLE_ARN_ECR_PUSH` | secret | the publisher role ARN for `agent-plugins/services/gcp-cloud-storage`, created by the agent-plugins registration |
| `NP_ARTIFACT_NRN` | variable | the NRN of the organization that owns the artifacts |
| `PACKAGE_STATE_AWS_ACCOUNT_ID`, `PACKAGE_TFSTATE_BUCKET`, `PACKAGE_TFSTATE_REGION` | organization secrets | where the publish stack keeps its state; the state role is `github-actions-<repository>-package-state` in that account, by convention |

`ARTIFACT_NP_API_KEY` comes from the organization. Each release publishes the
package `np-gcp-cloud-storage-bucket` from `gcs-bucket/publish`.
