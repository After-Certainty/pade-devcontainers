#!/usr/bin/env bash
# Child/container shell snippets intentionally defer variable expansion.
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONFIG="$ROOT/experiments/008-lifecycle-stale-state/.devcontainer/devcontainer.json"
VOLUME="pade-exp008-state"

cleanup() {
  if [[ -n "${last_container:-}" ]]; then
    docker rm -f "$last_container" >/dev/null 2>&1 || true
  fi
  docker volume rm -f "$VOLUME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

up() {
  devcontainer up --workspace-folder "$ROOT" --config "$CONFIG"
}

container_id() {
  python3 -c 'import json,sys; print(json.load(sys.stdin)["containerId"])'
}

assert_empty() {
  devcontainer exec     --workspace-folder "$ROOT"     --config "$CONFIG"     /bin/sh -c '
      test -f /pade-state/bindings.yaml
      grep -q "^capabilities: {}$" /pade-state/bindings.yaml
      test "$(stat -c "%a" /pade-state/bindings.yaml)" = "600"
    '
}

write_stale() {
  devcontainer exec     --workspace-folder "$ROOT"     --config "$CONFIG"     /bin/sh -c '
      umask 077
      cat >/pade-state/bindings.yaml <<EOF
version: "0.1"
capabilities:
  stale.authority:
    provider: broker
EOF
      chmod 600 /pade-state/bindings.yaml
    '
}

first_json="$(up)"
first_id="$(printf '%s' "$first_json" | container_id)"
last_container="$first_id"
assert_empty
write_stale

docker stop "$first_id" >/dev/null
second_json="$(up)"
second_id="$(printf '%s' "$second_json" | container_id)"
last_container="$second_id"

if [[ "$second_id" != "$first_id" ]]; then
  echo "expected stop/start to reuse the same container" >&2
  exit 1
fi
assert_empty
write_stale

docker rm -f "$second_id" >/dev/null
last_container=""
third_json="$(up)"
third_id="$(printf '%s' "$third_json" | container_id)"
last_container="$third_id"

if [[ "$third_id" == "$second_id" ]]; then
  echo "expected fresh recreation to use a new container" >&2
  exit 1
fi
assert_empty

echo "restart_container_reused=true"
echo "restart_stale_bindings=cleared"
echo "recreate_container_changed=true"
echo "persistent_volume_stale_bindings=cleared"
echo "experiment_008_lifecycle_stale_state=pass"
