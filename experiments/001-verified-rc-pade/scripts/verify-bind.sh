#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES="$ROOT/experiments/001-verified-rc-pade/fixtures"
RC_PADE_BIN="${RC_PADE_BIN:-$ROOT/.work/bin/rc-pade}"

if [[ ! -x "$RC_PADE_BIN" ]]; then
  echo "missing rc-pade binary: $RC_PADE_BIN" >&2
  exit 1
fi

if "$RC_PADE_BIN" bind --help 2>&1 | grep -q -- '--validation-report'; then
  echo "rc-pade bind unexpectedly exposes --validation-report" >&2
  exit 1
fi

ALLOW="$(tr -d '\r\n' < "$FIXTURES/allow-capabilities.txt")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BINDINGS="$TMP/bindings.yaml"
SESSION="$TMP/session.yaml"

"$RC_PADE_BIN" bind   --verified-profile "$FIXTURES/verified-profile.yaml"   --policy "$FIXTURES/policy.yaml"   --broker-binding "$FIXTURES/broker.json"   --allow-capabilities "$ALLOW"   --output "$BINDINGS"   --session-out "$SESSION"

grep -q '^  github.repo.read:' "$BINDINGS"
grep -q '^  github.repo.write:' "$BINDINGS"
grep -q 'provider: broker' "$BINDINGS"
grep -q 'https://broker.example.test' "$BINDINGS"
grep -q 'github.repo.read' "$SESSION"
grep -q 'github.repo.write' "$SESSION"

MODE="$(stat -c '%a' "$BINDINGS")"
if [[ "$MODE" != "600" ]]; then
  echo "bindings mode=$MODE, want 600" >&2
  exit 1
fi

GOOD_SHA="$(sha256sum "$BINDINGS" | awk '{print $1}')"
echo "happy_path_bindings_sha256=$GOOD_SHA mode=$MODE"

set +e
"$RC_PADE_BIN" bind   --verified-profile "$FIXTURES/verified-profile.yaml"   --policy "$FIXTURES/policy.yaml"   --broker-binding "$FIXTURES/broker.json"   --allow-capabilities "github.repo.read"   --output "$BINDINGS"   --session-out "$SESSION"
NEGATIVE_RC=$?
set -e

if [[ "$NEGATIVE_RC" -eq 0 ]]; then
  echo "expected insufficient allowlist to fail" >&2
  exit 1
fi

grep -q '^capabilities: {}$' "$BINDINGS"
MODE="$(stat -c '%a' "$BINDINGS")"
if [[ "$MODE" != "600" ]]; then
  echo "fail-closed bindings mode=$MODE, want 600" >&2
  exit 1
fi

EMPTY_SHA="$(sha256sum "$BINDINGS" | awk '{print $1}')"
echo "fail_closed_bindings_sha256=$EMPTY_SHA mode=$MODE rc=$NEGATIVE_RC"
echo "experiment_001_ci_smoke=pass"
