#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES="$ROOT/experiments/004-support-semantics/fixtures"
RC_PADE_BIN="${RC_PADE_BIN:-$ROOT/.work/bin/rc-pade}"

if [[ ! -x "$RC_PADE_BIN" ]]; then
  echo "missing rc-pade binary: $RC_PADE_BIN" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

run_supported() {
  local name=$1
  local profile=$2
  local expected_required=$3
  local output="$tmp/$name-bindings.yaml"
  local session="$tmp/$name-session.yaml"

  "$RC_PADE_BIN" bind     --verified-profile "$profile"     --policy "$FIXTURES/policy-supported.yaml"     --broker-binding "$FIXTURES/broker.json"     --allow-capabilities github.repo.read     --output "$output"     --session-out "$session"

  python3 - "$session" "$expected_required" <<'PY'
import sys
import yaml

path, expected = sys.argv[1:]
with open(path, encoding="utf-8") as f:
    session = yaml.safe_load(f)

caps = session["spec"]["capabilities"]
assert set(caps) == {"github.repo.read"}, caps
cap = caps["github.repo.read"]
assert cap["access"] == "read", cap
assert cap["required"] is (expected == "true"), cap
print(f"supported_required={cap['required']}")
PY

  grep -q 'github.repo.read:' "$output"
  [[ "$(stat -c '%a' "$output")" == "600" ]]
}

run_unsupported() {
  local name=$1
  local profile=$2
  local output="$tmp/$name-bindings.yaml"
  local session="$tmp/$name-session.yaml"
  local stderr="$tmp/$name-stderr.txt"

  printf 'version: "0.1"\ncapabilities:\n  stale.authority:\n    provider: broker\n' >"$output"
  chmod 600 "$output"

  set +e
  "$RC_PADE_BIN" bind     --verified-profile "$profile"     --policy "$FIXTURES/policy-unsupported.yaml"     --broker-binding "$FIXTURES/broker.json"     --allow-capabilities github.repo.read     --output "$output"     --session-out "$session"     2>"$stderr"
  local rc=$?
  set -e

  if [[ "$rc" -eq 0 ]]; then
    echo "$name unexpectedly succeeded" >&2
    exit 1
  fi

  grep -q 'no projection rule matches source_control/git' "$stderr"
  grep -q '^capabilities: {}$' "$output"
  [[ "$(stat -c '%a' "$output")" == "600" ]]

  echo "$name=unsupported_fail_closed rc=$rc"
}

run_supported required "$FIXTURES/profile-required.yaml" true
run_supported optional "$FIXTURES/profile-optional.yaml" false
run_unsupported unsupported-required "$FIXTURES/profile-required.yaml"
run_unsupported unsupported-optional "$FIXTURES/profile-optional.yaml"

echo "finding_optional_unsupported=current_rc_pade_fails_closed"
echo "experiment_004_support_semantics=pass"
