#!/usr/bin/env bats
# Unit tests for scripts/build_context: the service and link inputs it hands to
# OpenTofu. np is stubbed; nothing reaches GCP or nullplatform.

setup() {
  export SCRIPT="$BATS_TEST_DIRNAME/../scripts/build_context"
  export SERVICE_PATH="$BATS_TEST_DIRNAME/.."
  export VALUES="$BATS_TEST_TMPDIR/values.yaml"
  printf 'project_id: "acme-project"\nlocation: "us-east1"\ntfstate_bucket: "acme-tfstate"\n' > "$VALUES"
  np() { echo '{"results":[]}'; }
  export -f np
  export SERVICE='{"id":"3f887d63-bed5-4dbb-a522-861c854cfd6d","slug":"Monthly Reports","attributes":{}}'
}

# Runs build_context with $CONTEXT and prints the tofu variables it exported.
tofu_vars() {
  bash -c 'source "$SCRIPT" >/dev/null && echo "$TOFU_VARIABLES"'
}
link_prefix() {
  bash -c 'source "$SCRIPT" >/dev/null && echo "prefix=[$LINK_PATH_PREFIX]"'
}

service_context() { export CONTEXT="{\"type\":\"create\",\"service\":$SERVICE,\"parameters\":$1}"; }
link_context() {
  export ACTION_SOURCE=link
  export CONTEXT="{\"type\":\"create\",\"service\":$SERVICE,\"link\":{\"id\":\"l-1\",\"entity_nrn\":\"organization=1:account=2:namespace=3:application=123\",\"dimensions\":{\"environment\":\"development\"},\"attributes\":$1},\"parameters\":$1}"
}

@test "service: the bucket is named after the service slug" {
  service_context '{}'
  run tofu_vars
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .bucket_name)" = "np-gcs-monthly-reports-3f887d63" ]
}

@test "service: public access prevention defaults to enforced" {
  service_context '{}'
  run tofu_vars
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .public_access_prevention)" = "enforced" ]
}

@test "service: public access prevention can defer to the policy (inherited)" {
  service_context '{"public_access_prevention":"inherited"}'
  run tofu_vars
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r .public_access_prevention)" = "inherited" ]
}

@test "service: an unknown public access prevention value fails" {
  service_context '{"public_access_prevention":"public"}'
  run tofu_vars
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid public_access_prevention"* ]]
}

@test "link: no path_prefix means the whole bucket" {
  link_context '{"access_level":"read"}'
  run link_prefix
  [ "$status" -eq 0 ]
  [ "$output" = "prefix=[]" ]
}

@test "link: a path_prefix is passed on" {
  link_context '{"access_level":"read-write","path_prefix":"uploads/"}'
  run link_prefix
  [ "$status" -eq 0 ]
  [ "$output" = "prefix=[uploads/]" ]
}

@test "link: a path_prefix with a quote is refused (it goes into an IAM condition)" {
  link_context "{\"path_prefix\":\"up')||true||('\"}"
  run link_prefix
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid path_prefix"* ]]
}

@test "link: a path_prefix starting with / or containing .. is refused" {
  for p in "/uploads/" "a/../b"; do
    link_context "{\"path_prefix\":\"$p\"}"
    run link_prefix
    [ "$status" -ne 0 ]
  done
}

@test "link: a path_prefix longer than 512 characters is refused" {
  link_context "{\"path_prefix\":\"$(printf 'a%.0s' $(seq 1 513))\"}"
  run link_prefix
  [ "$status" -ne 0 ]
}
