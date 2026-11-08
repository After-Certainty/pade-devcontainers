#!/usr/bin/env bash
# Child/container shell snippets intentionally defer variable expansion.
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
UP_JSON="${UP_JSON:-$ROOT/.work/experiment-007-up.json}"

project="$(
  python3 - "$UP_JSON" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
print(data["composeProjectName"])
PY
)"

sidecar="$(
  docker ps     --filter "label=com.docker.compose.project=$project"     --filter "label=com.docker.compose.service=sidecar"     --format '{{.ID}}'
)"

if [[ -z "$sidecar" ]]; then
  echo "sidecar container not found for compose project $project" >&2
  exit 1
fi

docker exec "$sidecar" /bin/sh -c '
  test "$SIDECAR_MARKER" = "isolated"
  test -z "${GITHUB_TOKEN:-}"
  ! command -v pade >/dev/null 2>&1
  test ! -e /workspaces/pade-devcontainers
'

echo "compose_project=$project"
echo "sidecar_material=absent"
echo "sidecar_workspace_mount=absent"
echo "experiment_007_multi_container=pass"
