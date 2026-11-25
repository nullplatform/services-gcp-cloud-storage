# syntax=docker/dockerfile:1
# Worker image: the bridge runs the entrypoint on every action.
FROM public.ecr.aws/nullplatform/scopes/worker-bridge:2.0.7

# OpenTofu, pinned and checksum-verified, so no action downloads it at runtime.
ARG TOFU_VERSION=1.13.2
ARG TOFU_SHA256_AMD64=ac05d9952662c7db28dd57e93f0a68018837bfdf9342384ec0987977c16a9645
ARG TOFU_SHA256_ARM64=88e2d9e3f94f97b76ab2faf55ade87578f56aed19c5e45fa139d70e994366d1f
ARG TARGETARCH
RUN set -eu; \
    arch="${TARGETARCH:-}"; \
    if [ -z "$arch" ]; then \
      case "$(uname -m)" in x86_64|amd64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; *) exit 1 ;; esac; \
    fi; \
    case "$arch" in amd64) sha="$TOFU_SHA256_AMD64" ;; arm64) sha="$TOFU_SHA256_ARM64" ;; *) exit 1 ;; esac; \
    curl -fsSL -o /tmp/tofu.tar.gz \
      "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_${arch}.tar.gz"; \
    echo "${sha}  /tmp/tofu.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/tofu.tar.gz -C /usr/local/bin tofu; \
    rm -f /tmp/tofu.tar.gz; \
    tofu version

# np chmods the action script in place, so the tree belongs to the runtime uid.
COPY --chown=10001:10001 . /app/pkg
ENV NP_PACKAGE_NAME=gcp-cloud-storage-bucket \
    NP_SERVICE_PATH=/app/pkg/gcs-bucket \
    NP_SCOPE_ENTRYPOINT=/app/pkg/gcs-bucket/entrypoint/entrypoint

USER 10001:10001
