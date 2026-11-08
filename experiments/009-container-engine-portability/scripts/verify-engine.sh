#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "usage: verify-engine.sh docker|podman" >&2
  exit 2
fi

ENGINE="$1"
case "$ENGINE" in
  docker|podman) ;;
  *)
    echo "unsupported engine: $ENGINE" >&2
    exit 2
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONFIG="$ROOT/.devcontainer/experiments/009/devcontainer.json"
STAGED_FEATURE="$ROOT/.devcontainer/experiments/009/features/pade"

rm -rf "$STAGED_FEATURE"
mkdir -p "$STAGED_FEATURE"
cp "$ROOT/src/pade/devcontainer-feature.json" "$STAGED_FEATURE/devcontainer-feature.json"
cp "$ROOT/src/pade/install.sh" "$STAGED_FEATURE/install.sh"
chmod 0755 "$STAGED_FEATURE/install.sh"

cmp "$ROOT/src/pade/devcontainer-feature.json" "$STAGED_FEATURE/devcontainer-feature.json"
cmp "$ROOT/src/pade/install.sh" "$STAGED_FEATURE/install.sh"

cleanup() {
  if [[ -n "${container_id:-}" ]]; then
    "$ENGINE" rm -f "$container_id" >/dev/null 2>&1 || true
  fi
  rm -rf "$STAGED_FEATURE"
}
trap cleanup EXIT

up_json="$(
  devcontainer up     --docker-path "$ENGINE"     --workspace-folder "$ROOT"     --config "$CONFIG"
)"

container_id="$(
  printf '%s' "$up_json" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["containerId"])'
)"

test -n "$container_id"

"$ENGINE" exec "$container_id" /bin/sh -c '
  command -v pade-devcontainer-init >/dev/null
  command -v pade-devcontainer-bind >/dev/null
  test -f /tmp/pade-devcontainer-bindings.yaml
  grep -q "^capabilities: {}$" /tmp/pade-devcontainer-bindings.yaml
  test "$(stat -c "%a" /tmp/pade-devcontainer-bindings.yaml)" = "600"
'

echo "container_engine=$ENGINE"
echo "feature_install=pass"
echo "fail_closed_bindings=pass"
echo "experiment_009_container_engine_portability=pass"
