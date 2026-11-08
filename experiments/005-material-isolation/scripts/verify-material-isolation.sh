#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES="$ROOT/experiments/005-material-isolation/fixtures"
PADE_BIN="${PADE_BIN:-$ROOT/.work/bin/pade}"
TOKEN="pade-demo-ksm-token"

test -x "$PADE_BIN"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  echo "ordinary shell unexpectedly has GITHUB_TOKEN" >&2
  exit 1
fi

if tr '\0' '\n' </proc/1/environ 2>/dev/null | grep -q '^GITHUB_TOKEN='; then
  echo "container PID 1 unexpectedly has GITHUB_TOKEN" >&2
  exit 1
fi

if grep -R -F "$TOKEN" "$FIXTURES"; then
  echo "resolved Material is persisted in checked-in fixtures" >&2
  exit 1
fi

caps="$(
  PADE_KSM_FAKE=1 "$PADE_BIN" capabilities     -f "$FIXTURES/pade.yaml"     --bindings "$FIXTURES/bindings.yaml"
)"
printf '%s\n' "$caps" | grep -q 'github.repo.read'
if printf '%s\n' "$caps" | grep -Fq "$TOKEN"; then
  echo "capabilities output leaked Material" >&2
  exit 1
fi

# Variables in the child script intentionally expand inside the PADE child.
# shellcheck disable=SC2016
child_out="$(
  PADE_KSM_FAKE=1 KSM_CONFIG=synthetic-bootstrap-must-not-reach-child     "$PADE_BIN" exec       -f "$FIXTURES/pade.yaml"       --bindings "$FIXTURES/bindings.yaml"       --capability github.repo.read       --quiet --       /bin/sh -c '
        test "$GITHUB_TOKEN" = "pade-demo-ksm-token"
        test -z "${KSM_CONFIG:-}"
        printf child-isolated-ok
      '
)"
[[ "$child_out" == "child-isolated-ok" ]]

# GITHUB_TOKEN intentionally expands only inside the PADE child.
# shellcheck disable=SC2016
redacted="$(
  PADE_KSM_FAKE=1 "$PADE_BIN" exec     -f "$FIXTURES/pade.yaml"     --bindings "$FIXTURES/bindings.yaml"     --capability github.repo.read     --quiet --     /bin/sh -c 'printf "%s" "$GITHUB_TOKEN"'
)"
[[ "$redacted" == "[REDACTED]" ]]
if [[ "$redacted" == *"$TOKEN"* ]]; then
  echo "exact Material escaped PADE redaction" >&2
  exit 1
fi

test -z "${GITHUB_TOKEN:-}"
/bin/sh -c 'test -z "${GITHUB_TOKEN:-}"'

if grep -Fq "$TOKEN" "$FIXTURES/bindings.yaml"; then
  echo "bindings persisted Material after execution" >&2
  exit 1
fi

echo "ordinary_shell_material=absent"
echo "pade_child_material=present"
echo "post_exec_material=absent"
echo "exact_stdout_material=redacted"
echo "experiment_005_material_isolation=pass"
