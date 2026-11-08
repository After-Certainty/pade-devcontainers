#!/usr/bin/env bash
# Child-shell snippets intentionally defer capability variable expansion.
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES="$ROOT/experiments/006-multiple-consumers/fixtures"
PADE_BIN="${PADE_BIN:-$ROOT/.work/bin/pade}"

test -x "$PADE_BIN"
test -z "${GITHUB_READ_TOKEN:-}"
test -z "${GITHUB_WRITE_TOKEN:-}"

PADE_KSM_FAKE=1 "$PADE_BIN" exec   -f "$FIXTURES/pade.yaml"   --bindings "$FIXTURES/bindings.yaml"   --capability github.repo.read   --quiet --   /bin/sh -c '
    test "$GITHUB_READ_TOKEN" = "pade-demo-alice-ksm-token"
    test -z "${GITHUB_WRITE_TOKEN:-}"
  '

PADE_KSM_FAKE=1 "$PADE_BIN" exec   -f "$FIXTURES/pade.yaml"   --bindings "$FIXTURES/bindings.yaml"   --capability github.repo.write   --quiet --   /bin/sh -c '
    test "$GITHUB_WRITE_TOKEN" = "pade-demo-bob-ksm-token"
    test -z "${GITHUB_READ_TOKEN:-}"
  '

PADE_KSM_FAKE=1 "$PADE_BIN" exec   -f "$FIXTURES/pade.yaml"   --bindings "$FIXTURES/bindings.yaml"   --capability github.repo.read   --capability github.repo.write   --quiet --   /bin/sh -c '
    test "$GITHUB_READ_TOKEN" = "pade-demo-alice-ksm-token"
    test "$GITHUB_WRITE_TOKEN" = "pade-demo-bob-ksm-token"
  '

test -z "${GITHUB_READ_TOKEN:-}"
test -z "${GITHUB_WRITE_TOKEN:-}"
/bin/sh -c 'test -z "${GITHUB_READ_TOKEN:-}" && test -z "${GITHUB_WRITE_TOKEN:-}"'

echo "read_consumer=read_only"
echo "write_consumer=write_only"
echo "combined_consumer=explicit_both"
echo "ordinary_shell=none"
echo "experiment_006_multiple_consumers=pass"
