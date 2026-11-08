#!/usr/bin/env bash
# Live PADE broker authorization against deployed broker using Dev Container bindings.
# Reuses Exp 015 probe: github.repo.read → After-Certainty/after-certainty; write denied.
# Never records tokens or Material values.
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORK="$ROOT/.work/experiment-001"
PADE_BIN="${PADE_BIN:-$ROOT/.work/bin/pade}"
BINDINGS="${PADE_BINDINGS_PATH:-/tmp/pade-exp001/bindings.yaml}"
SESSION="${PADE_SESSION_PATH:-$WORK/session.yaml}"
OUT="$WORK/broker-live-safe.txt"

test -x "$PADE_BIN"
test -f "$BINDINGS"
test -f "$SESSION"
grep -q 'github.repo.read:' "$BINDINGS"
grep -q 'github.repo.write:' "$BINDINGS"

for var in GITHUB_TOKEN GH_TOKEN AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
  if [[ -n "${!var:-}" ]]; then
    echo "ambient credential env must be unset before live broker proof: $var" >&2
    exit 1
  fi
done

mkdir -p "$WORK"

# Positive read.
# Variables expand inside the PADE child only.
set +e
READ_OUT="$("$PADE_BIN" exec \
  -f "$SESSION" \
  --bindings "$BINDINGS" \
  --capability github.repo.read \
  --quiet -- \
  /bin/sh -c '
    test -n "${GITHUB_TOKEN:-}"
    code=$(curl -sS -o /tmp/pade-exp001-repo.json -w "%{http_code}" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "User-Agent: pade-devcontainers-exp001" \
      https://api.github.com/repos/After-Certainty/after-certainty)
    test "$code" = "200"
    python3 - <<PY
import json
d=json.load(open("/tmp/pade-exp001-repo.json"))
assert d.get("full_name")=="After-Certainty/after-certainty"
assert d.get("name")=="after-certainty"
print("repo_full_name=After-Certainty/after-certainty")
PY
  ' 2>"$WORK/read.err")"
READ_RC=$?
set -e

if [[ "$READ_RC" -ne 0 ]]; then
  echo "github.repo.read live path failed rc=$READ_RC" >&2
  # Show non-secret stderr only (PADE should redact tokens).
  sed -E 's/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[JWT_REDACTED]/g; s/gh[pousr]_[A-Za-z0-9_]+/[GH_REDACTED]/g' "$WORK/read.err" >&2 || true
  exit 1
fi
printf '%s\n' "$READ_OUT" | grep -q 'repo_full_name=After-Certainty/after-certainty'
# Parent must remain clean.
test -z "${GITHUB_TOKEN:-}"
test -z "${GH_TOKEN:-}"

# Negative write: broker denial; child must not run.
set +e
WRITE_OUT="$("$PADE_BIN" exec \
  -f "$SESSION" \
  --bindings "$BINDINGS" \
  --capability github.repo.write \
  --quiet -- \
  /bin/sh -c 'printf CHILD_RAN_UNEXPECTEDLY' 2>"$WORK/write.err")"
WRITE_RC=$?
set -e

if [[ "$WRITE_RC" -eq 0 ]]; then
  echo "expected github.repo.write to be denied by broker" >&2
  exit 1
fi
if printf '%s' "$WRITE_OUT" | grep -q 'CHILD_RAN_UNEXPECTEDLY'; then
  echo "write child ran despite broker denial" >&2
  exit 1
fi
# Accept PADE/broker denial evidence without requiring exact wording.
if ! grep -Eiq '403|denied|forbidden|not authorized|authorization' "$WORK/write.err"; then
  echo "write denial stderr lacked denial evidence" >&2
  sed -E 's/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[JWT_REDACTED]/g' "$WORK/write.err" >&2 || true
  exit 1
fi

DENIAL_CLASS="broker-denied"
if grep -q '403' "$WORK/write.err"; then
  DENIAL_CLASS="broker-denied-http-403"
fi

cat >"$OUT" <<EOF
live_authorization_tested=true
endpoint_recorded=false
github_repo_read=authorized
github_repo_read_probe=After-Certainty/after-certainty
github_repo_read_exit=$READ_RC
github_repo_write=$DENIAL_CLASS
github_repo_write_exit=$WRITE_RC
child_ran_on_write=false
durable_provider_credentials_introduced=false
token_values_recorded=false
EOF

echo "github.repo.read=authorized"
echo "github.repo.write=$DENIAL_CLASS"
echo "experiment_001_live_broker=pass"
