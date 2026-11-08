#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
REGISTRY="localhost:5000"
NAMESPACE="after-certainty/pade-devcontainers"
PACKAGE_DIR="$ROOT/.work/experiment-010-package"
CONSUMER_DIR="$ROOT/.work/experiment-010-consumer"
REGISTRY_NAME="pade-exp010-registry"

cleanup() {
  if [[ -n "${consumer_id:-}" ]]; then
    docker rm -f "$consumer_id" >/dev/null 2>&1 || true
  fi
  docker rm -f "$REGISTRY_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

rm -rf "$PACKAGE_DIR" "$CONSUMER_DIR"
mkdir -p "$ROOT/.work"

docker run -d   --name "$REGISTRY_NAME"   -p 5000:5000   registry:2 >/dev/null

for _ in $(seq 1 30); do
  if curl -fsS "http://$REGISTRY/v2/" >/dev/null; then
    break
  fi
  sleep 1
done
curl -fsS "http://$REGISTRY/v2/" >/dev/null

devcontainer features package   "$ROOT/src"   --output-folder "$PACKAGE_DIR"   --force-clean-output-folder

test -f "$PACKAGE_DIR/devcontainer-feature-pade.tgz"
test -f "$PACKAGE_DIR/devcontainer-collection.json"

python3 - "$PACKAGE_DIR/devcontainer-collection.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)

features = data["features"]
assert len(features) == 1, features
feature = features[0]
assert feature["id"] == "pade", feature
assert feature["version"] == "0.1.0", feature
print("package_metadata=pass")
PY

publish_json="$(
  devcontainer features publish     "$ROOT/src"     --registry "$REGISTRY"     --namespace "$NAMESPACE"
)"

digest="$(
  printf '%s' "$publish_json" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["pade"]["digest"])'
)"

case "$digest" in
  sha256:*) ;;
  *)
    echo "unexpected published digest: $digest" >&2
    exit 1
    ;;
esac

manifest="$(
  devcontainer features info manifest     "$REGISTRY/$NAMESPACE/pade@$digest"
)"
printf '%s' "$manifest" |
  grep -q 'application/vnd.devcontainers.layer.v1+tar'

mkdir -p "$CONSUMER_DIR/.devcontainer"
cat >"$CONSUMER_DIR/.devcontainer/devcontainer.json" <<EOF
{
  "name": "pade-experiment-010-clean-consumer",
  "image": "ubuntu:24.04",
  "remoteUser": "root",
  "features": {
    "$REGISTRY/$NAMESPACE/pade@$digest": {}
  },
  "containerEnv": {
    "PADE_BINDINGS_PATH": "/tmp/pade-distributed-bindings.yaml"
  }
}
EOF

if [[ -e "$CONSUMER_DIR/src/pade" ]]; then
  echo "clean consumer unexpectedly contains local Feature source" >&2
  exit 1
fi

up_json="$(
  devcontainer up     --workspace-folder "$CONSUMER_DIR"
)"

consumer_id="$(
  printf '%s' "$up_json" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["containerId"])'
)"

docker exec "$consumer_id" /bin/sh -c '
  command -v pade-devcontainer-init >/dev/null
  command -v pade-devcontainer-bind >/dev/null
  test -f /tmp/pade-distributed-bindings.yaml
  grep -q "^capabilities: {}$" /tmp/pade-distributed-bindings.yaml
  test "$(stat -c "%a" /tmp/pade-distributed-bindings.yaml)" = "600"
'

echo "published_digest=$digest"
echo "oci_manifest=pass"
echo "clean_consumer_local_source=absent"
echo "distributed_feature_install=pass"
echo "experiment_010_oci_feature_distribution=pass"
