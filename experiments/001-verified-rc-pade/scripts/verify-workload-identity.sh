#!/usr/bin/env bash
# Probe audience-bound GCE workload identity from inside the Dev Container.
# Never prints JWT/token values. Writes safe claims summary only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORK="$ROOT/.work/experiment-001"
BROKER_LIVE="${PADE_BROKER_LIVE:-$WORK/broker.live.json}"
OUT="$WORK/identity-safe.txt"

mkdir -p "$WORK"
test -f "$BROKER_LIVE"

AUDIENCE="$(python3 - <<PY
import json
from pathlib import Path
data = json.loads(Path("$BROKER_LIVE").read_text())
broker = data.get("broker", data)
print(broker.get("audience") or broker.get("endpoint") or "")
PY
)"
if [[ -z "$AUDIENCE" ]]; then
  echo "missing broker audience" >&2
  exit 1
fi

META_ROOT="http://metadata.google.internal/computeMetadata/v1/"
IDENTITY_URL="http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=${AUDIENCE}&format=full"

set +e
ROOT_CODE="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 -H 'Metadata-Flavor: Google' "$META_ROOT")"
ROOT_CURL_RC=$?
set -e

if [[ "$ROOT_CURL_RC" -ne 0 || "$ROOT_CODE" != "200" ]]; then
  cat >"$OUT" <<EOF
gce_metadata_reachable=false
metadata_http_code=${ROOT_CODE:-none}
curl_rc=$ROOT_CURL_RC
mechanism=none
durable_credentials_introduced=false
EOF
  echo "gce_metadata_reachable=false code=${ROOT_CODE:-none}"
  exit 2
fi

# Mint audience-bound identity token; never echo it.
TOKEN="$(curl -fsS --connect-timeout 5 -H 'Metadata-Flavor: Google' "$IDENTITY_URL")"
if [[ -z "$TOKEN" || "$TOKEN" != *.* ]]; then
  echo "metadata identity mint failed" >&2
  exit 1
fi

python3 - "$TOKEN" "$AUDIENCE" "$OUT" <<'PY'
import base64, json, os, sys, time
token, audience, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
parts = token.split(".")
if len(parts) < 2:
    raise SystemExit("not a JWT-shaped token")
pad = "=" * (-len(parts[1]) % 4)
claims = json.loads(base64.urlsafe_b64decode(parts[1] + pad))
# Safe claims only — never write sub or raw token.
email = claims.get("email", "")
iss = claims.get("iss", "")
aud = claims.get("aud", "")
exp = int(claims.get("exp", 0) or 0)
iat = int(claims.get("iat", 0) or 0)
ttl = max(0, exp - iat) if exp and iat else 0
now = int(time.time())
lines = [
    "gce_metadata_reachable=true",
    "mechanism=gce",
    "identity_endpoint=metadata.google.internal/.../identity",
    f"audience_selected=broker_audience",
    f"audience_matches={str(aud == audience).lower()}",
    f"iss={iss}",
    f"email={email}",
    f"ttl_seconds={ttl}",
    f"token_not_expired={str(exp > now).lower()}",
    "raw_token_recorded=false",
    "numeric_subject_recorded=false",
    "durable_credentials_introduced=false",
]
Path = __import__("pathlib").Path
Path(out_path).write_text("\n".join(lines) + "\n")
print("\n".join(lines))
# Drop token from locals as soon as possible.
del token, parts, claims
PY

# Ensure ambient durable cloud creds were not introduced for this probe.
for var in GOOGLE_APPLICATION_CREDENTIALS AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY GITHUB_TOKEN GH_TOKEN; do
  if [[ -n "${!var:-}" ]]; then
    echo "unexpected durable credential env present: $var" >&2
    exit 1
  fi
done

echo "experiment_001_workload_identity=pass"
