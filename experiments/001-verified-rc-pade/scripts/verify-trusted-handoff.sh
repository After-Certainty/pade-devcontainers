#!/usr/bin/env bash
# Verify signed RC handoff, bind only on success, and prove corrupted-handoff fail-closed.
# Intended to run inside the Experiment 001 live Dev Container (workspace mounted).
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES="$ROOT/experiments/001-verified-rc-pade/fixtures"
HANDOFF="$FIXTURES/handoff"
WORK="$ROOT/.work/experiment-001"
VERIFY_HANDOFF_BIN="${VERIFY_HANDOFF_BIN:-$ROOT/.work/bin/verify-handoff}"
RC_PADE_BIN="${RC_PADE_BIN:-$ROOT/.work/bin/rc-pade}"
BINDINGS="${PADE_BINDINGS_PATH:-/tmp/pade-exp001/bindings.yaml}"
BROKER_LIVE="${PADE_BROKER_LIVE:-$WORK/broker.live.json}"
EXPECTED_PROFILE_SHA256="53fe0bca5664c9b889304c881d6643cec163f449a9d02a91fd5a6d635ad62e19"
ALLOW="$(tr -d '\r\n' < "$FIXTURES/allow-capabilities.txt")"

test -x "$VERIFY_HANDOFF_BIN"
test -x "$RC_PADE_BIN"
test -f "$BROKER_LIVE"
test ! -e "$HANDOFF/signer.key"

mkdir -p "$(dirname "$BINDINGS")" "$WORK"
# Fail-closed init before trust.
if command -v pade-devcontainer-init >/dev/null 2>&1; then
  PADE_BINDINGS_PATH="$BINDINGS" pade-devcontainer-init >/dev/null
else
  umask 077
  printf 'version: "0.1"\ncapabilities: {}\n' >"$BINDINGS"
  chmod 600 "$BINDINGS"
fi

# Positive verification.
VERIFIED="$WORK/verified-profile.yaml"
rm -f "$VERIFIED"
VERIFIED_PROFILE_OUT="$VERIFIED" "$VERIFY_HANDOFF_BIN" "$HANDOFF" "$HANDOFF/trusted.pub"
ACTUAL_SHA="$(sha256sum "$VERIFIED" | awk '{print $1}')"
if [[ "$ACTUAL_SHA" != "$EXPECTED_PROFILE_SHA256" ]]; then
  echo "verified profile digest mismatch: $ACTUAL_SHA" >&2
  exit 1
fi
MODE="$(stat -c '%a' "$VERIFIED")"
[[ "$MODE" == "600" ]]

# Bind only after verification.
SESSION="$WORK/session.yaml"
if command -v pade-devcontainer-bind >/dev/null 2>&1; then
  PADE_BINDINGS_PATH="$BINDINGS" RC_PADE_BIN="$RC_PADE_BIN" \
    pade-devcontainer-bind "$VERIFIED" "$WORK/policy.yaml" "$BROKER_LIVE" "$ALLOW" "$SESSION"
else
  "$RC_PADE_BIN" bind \
    --verified-profile "$VERIFIED" \
    --policy "$WORK/policy.yaml" \
    --broker-binding "$BROKER_LIVE" \
    --allow-capabilities "$ALLOW" \
    --output "$BINDINGS" \
    --session-out "$SESSION"
fi

grep -q 'github.repo.read:' "$BINDINGS"
grep -q 'github.repo.write:' "$BINDINGS"
grep -q 'provider: broker' "$BINDINGS"
# Live endpoint must not equal the CI fixture example.
if grep -q 'broker.example.test' "$BINDINGS"; then
  echo "bindings unexpectedly contain CI fixture broker" >&2
  exit 1
fi
MODE="$(stat -c '%a' "$BINDINGS")"
[[ "$MODE" == "600" ]]
GOOD_SHA="$(sha256sum "$BINDINGS" | awk '{print $1}')"
echo "trusted_handoff_bind=pass profile_sha256=$ACTUAL_SHA bindings_sha256=$GOOD_SHA mode=$MODE"

# Negative: corrupt only the signed evidence bytes, then require fail-closed.
CORRUPT_DIR="$WORK/handoff-corrupt"
rm -rf "$CORRUPT_DIR"
mkdir -p "$CORRUPT_DIR/extensions"
cp -a "$HANDOFF/." "$CORRUPT_DIR/"
python3 - <<PY
from pathlib import Path
p = Path("$CORRUPT_DIR/evidence.json")
data = p.read_bytes()
# Flip one byte in the JSON payload without touching the signature file.
ba = bytearray(data)
ba[-2] = (ba[-2] + 1) % 256
p.write_bytes(bytes(ba))
PY

# Seed stale non-empty bindings to prove they are cleared / not reused as authority.
umask 077
cat >"$BINDINGS" <<'EOF'
version: "0.1"
capabilities:
  stale.authority:
    provider: broker
EOF
chmod 600 "$BINDINGS"

set +e
VERIFIED_PROFILE_OUT="$WORK/verified-profile.corrupt.yaml" \
  "$VERIFY_HANDOFF_BIN" "$CORRUPT_DIR" "$CORRUPT_DIR/trusted.pub" \
  >"$WORK/corrupt-verify.out" 2>"$WORK/corrupt-verify.err"
CORRUPT_RC=$?
set -e
if [[ "$CORRUPT_RC" -eq 0 ]]; then
  echo "expected corrupted handoff verification to fail" >&2
  exit 1
fi
if [[ -f "$WORK/verified-profile.corrupt.yaml" ]]; then
  echo "corrupt path must not emit verified profile" >&2
  exit 1
fi
grep -q 'untrusted_handoff' "$WORK/corrupt-verify.err"

# Bind must not be invoked on the corrupt path. Clear to empty via init semantics.
if command -v pade-devcontainer-init >/dev/null 2>&1; then
  PADE_BINDINGS_PATH="$BINDINGS" pade-devcontainer-init >/dev/null
else
  umask 077
  printf 'version: "0.1"\ncapabilities: {}\n' >"$BINDINGS"
  chmod 600 "$BINDINGS"
fi
grep -q '^capabilities: {}$' "$BINDINGS"
MODE="$(stat -c '%a' "$BINDINGS")"
[[ "$MODE" == "600" ]]
echo "corrupted_handoff_fail_closed=pass rc=$CORRUPT_RC mode=$MODE"

# Restore valid handoff and re-bind.
VERIFIED_PROFILE_OUT="$VERIFIED" "$VERIFY_HANDOFF_BIN" "$HANDOFF" "$HANDOFF/trusted.pub"
if command -v pade-devcontainer-bind >/dev/null 2>&1; then
  PADE_BINDINGS_PATH="$BINDINGS" RC_PADE_BIN="$RC_PADE_BIN" \
    pade-devcontainer-bind "$VERIFIED" "$WORK/policy.yaml" "$BROKER_LIVE" "$ALLOW" "$SESSION"
else
  "$RC_PADE_BIN" bind \
    --verified-profile "$VERIFIED" \
    --policy "$WORK/policy.yaml" \
    --broker-binding "$BROKER_LIVE" \
    --allow-capabilities "$ALLOW" \
    --output "$BINDINGS" \
    --session-out "$SESSION"
fi
grep -q 'github.repo.read:' "$BINDINGS"
echo "trusted_handoff_recovery=pass"
echo "experiment_001_trusted_handoff=pass"
