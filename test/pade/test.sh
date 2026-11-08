#!/bin/bash
set -euo pipefail

source dev-container-features-test-lib

bindings=/tmp/pade-feature-bindings.yaml
export PADE_BINDINGS_PATH="$bindings"

check "init helper installed" command -v pade-devcontainer-init
check "bind helper installed" command -v pade-devcontainer-bind
check "caller owns rc-pade installation" bash -c '! command -v rc-pade >/dev/null 2>&1'

check "initialize fail-closed bindings" pade-devcontainer-init
check "empty capabilities" grep -q '^capabilities: {}$' "$bindings"
check "mode 0600" bash -c '[ "$(stat -c "%a" "$PADE_BINDINGS_PATH")" = "600" ]'

printf 'stale: authority\n' >"$bindings"
set +e
pade-devcontainer-bind /tmp/profile.yaml /tmp/policy.yaml /tmp/broker.json github.repo.read >/tmp/pade-bind.out 2>/tmp/pade-bind.err
rc=$?
set -e

check "bind fails without caller-owned rc-pade" bash -c '[ "$1" -eq 127 ]' -- "$rc"
check "failed bind cleared stale state" grep -q '^capabilities: {}$' "$bindings"
check "failed bind preserves mode" bash -c '[ "$(stat -c "%a" "$PADE_BINDINGS_PATH")" = "600" ]'

reportResults
