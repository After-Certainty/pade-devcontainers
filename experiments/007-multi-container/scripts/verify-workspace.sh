#!/usr/bin/env bash
# Child-shell variables intentionally expand only inside the PADE child.
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES="$ROOT/experiments/007-multi-container/fixtures"
PADE_BIN="${PADE_BIN:-$ROOT/.work/bin/pade}"

test -x "$PADE_BIN"
test -z "${GITHUB_TOKEN:-}"
test -z "${SIDECAR_MARKER:-}"

PADE_KSM_FAKE=1 "$PADE_BIN" exec   -f "$FIXTURES/pade.yaml"   --bindings "$FIXTURES/bindings.yaml"   --capability github.repo.read   --quiet --   /bin/sh -c 'test "$GITHUB_TOKEN" = "pade-demo-ksm-token"'

test -z "${GITHUB_TOKEN:-}"

echo "workspace_ambient_material=absent"
echo "workspace_pade_child_material=present"
echo "workspace_sidecar_env=absent"
