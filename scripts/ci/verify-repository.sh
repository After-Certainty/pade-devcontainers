#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP1="$ROOT/experiments/001-verified-rc-pade"
EXP2="$ROOT/experiments/002-devcontainer-feature"
EXP3="$ROOT/experiments/003-composed-demand"
EXP4="$ROOT/experiments/004-support-semantics"
EXP5="$ROOT/experiments/005-material-isolation"
EXP6="$ROOT/experiments/006-multiple-consumers"
EXP7="$ROOT/experiments/007-multi-container"
EXP8="$ROOT/experiments/008-lifecycle-stale-state"
EXP9="$ROOT/experiments/009-container-engine-portability"
EXP10="$ROOT/experiments/010-oci-feature-distribution"
PROV="$ROOT/experiments/provenance"
PROV_CODER="$PROV/coder-2026-11-08"

required=(
  "$ROOT/README.md"
  "$ROOT/experiments/README.md"
  "$ROOT/.devcontainer/devcontainer.json"
  "$ROOT/.github/workflows/experiment-001.yml"
  "$ROOT/.github/workflows/experiments-002-004.yml"
  "$ROOT/.github/workflows/experiments-005-006.yml"
  "$ROOT/.github/workflows/experiments-007-008.yml"
  "$ROOT/.github/workflows/experiments-009-010.yml"
  "$ROOT/src/pade/devcontainer-feature.json"
  "$ROOT/src/pade/install.sh"
  "$ROOT/test/pade/test.sh"
  "$EXP1/README.md"
  "$EXP1/fixtures/verified-profile.yaml"
  "$EXP1/fixtures/policy.yaml"
  "$EXP1/fixtures/allow-capabilities.txt"
  "$EXP1/fixtures/broker.json"
  "$EXP1/fixtures/handoff/profile.yaml"
  "$EXP1/fixtures/handoff/evidence.json"
  "$EXP1/fixtures/handoff/evidence.sig"
  "$EXP1/fixtures/handoff/trusted.pub"
  "$EXP1/fixtures/handoff/README.md"
  "$EXP1/scripts/verify-bind.sh"
  "$EXP1/scripts/prepare-live-tools.sh"
  "$EXP1/scripts/verify-trusted-handoff.sh"
  "$EXP1/scripts/verify-workload-identity.sh"
  "$EXP1/scripts/verify-live-broker.sh"
  "$EXP1/scripts/verify-live-lifecycle.sh"
  "$EXP1/scripts/verify-handoff/main.go"
  "$ROOT/.devcontainer/experiments/001/devcontainer.json"
  "$EXP2/README.md"
  "$EXP3/README.md"
  "$EXP3/scripts/verify-composition.sh"
  "$EXP4/README.md"
  "$EXP4/fixtures/profile-required.yaml"
  "$EXP4/fixtures/profile-optional.yaml"
  "$EXP4/fixtures/policy-supported.yaml"
  "$EXP4/fixtures/policy-unsupported.yaml"
  "$EXP4/fixtures/broker.json"
  "$EXP4/scripts/verify-support-semantics.sh"
  "$EXP5/README.md"
  "$EXP5/fixtures/pade.yaml"
  "$EXP5/fixtures/bindings.yaml"
  "$EXP5/scripts/verify-material-isolation.sh"
  "$EXP6/README.md"
  "$EXP6/fixtures/pade.yaml"
  "$EXP6/fixtures/bindings.yaml"
  "$EXP6/scripts/verify-multiple-consumers.sh"
  "$EXP7/README.md"
  "$EXP7/.devcontainer/devcontainer.json"
  "$EXP7/.devcontainer/docker-compose.yml"
  "$EXP7/fixtures/pade.yaml"
  "$EXP7/fixtures/bindings.yaml"
  "$EXP7/scripts/verify-workspace.sh"
  "$EXP7/scripts/verify-sidecar.sh"
  "$EXP8/README.md"
  "$ROOT/.devcontainer/experiments/008/devcontainer.json"
  "$EXP8/scripts/verify-lifecycle.sh"
  "$EXP9/README.md"
  "$ROOT/.devcontainer/experiments/009/devcontainer.json"
  "$EXP9/scripts/verify-engine.sh"
  "$EXP10/README.md"
  "$EXP10/scripts/verify-distribution.sh"
  "$PROV/README.md"
  "$PROV_CODER/environment.md"
  "$PROV_CODER/001.yaml"
  "$PROV_CODER/002.yaml"
  "$PROV_CODER/003.yaml"
  "$PROV_CODER/004.yaml"
  "$PROV_CODER/005.yaml"
  "$PROV_CODER/006.yaml"
  "$PROV_CODER/007.yaml"
  "$PROV_CODER/008.yaml"
  "$PROV_CODER/009.yaml"
  "$PROV_CODER/010.yaml"
)

for path in "${required[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
done

python3 - \
  "$ROOT/.devcontainer/devcontainer.json" \
  "$ROOT/src/pade/devcontainer-feature.json" \
  "$EXP1/fixtures/broker.json" \
  "$EXP4/fixtures/broker.json" \
  "$EXP7/.devcontainer/devcontainer.json" \
  "$ROOT/.devcontainer/experiments/008/devcontainer.json" \
  "$ROOT/.devcontainer/experiments/009/devcontainer.json" \
  "$ROOT/.devcontainer/experiments/001/devcontainer.json" <<'PY'
import json
import sys

for path in sys.argv[1:]:
    with open(path, "r", encoding="utf-8") as f:
        json.load(f)
    print(f"json_ok={path}")

with open(sys.argv[2], "r", encoding="utf-8") as f:
    feature = json.load(f)

assert feature["id"] == "pade"
assert feature["version"] == "0.1.0"
assert feature["name"]
assert feature["postCreateCommand"] == "pade-devcontainer-init"
assert feature["postStartCommand"] == "pade-devcontainer-init"
print("feature_metadata=pass")
PY

shellcheck \
  "$ROOT/scripts/ci/verify-repository.sh" \
  "$EXP1/scripts/verify-bind.sh" \
  "$EXP1/scripts/prepare-live-tools.sh" \
  "$EXP1/scripts/verify-trusted-handoff.sh" \
  "$EXP1/scripts/verify-workload-identity.sh" \
  "$EXP1/scripts/verify-live-broker.sh" \
  "$EXP1/scripts/verify-live-lifecycle.sh" \
  "$EXP3/scripts/verify-composition.sh" \
  "$EXP4/scripts/verify-support-semantics.sh" \
  "$EXP5/scripts/verify-material-isolation.sh" \
  "$EXP6/scripts/verify-multiple-consumers.sh" \
  "$EXP7/scripts/verify-workspace.sh" \
  "$EXP7/scripts/verify-sidecar.sh" \
  "$EXP8/scripts/verify-lifecycle.sh" \
  "$EXP9/scripts/verify-engine.sh" \
  "$EXP10/scripts/verify-distribution.sh"

integration_scripts=(
  "$ROOT/.devcontainer/devcontainer.json"
  "$ROOT/.devcontainer/experiments/001/devcontainer.json"
  "$ROOT/src/pade/install.sh"
  "$EXP1/scripts/verify-bind.sh"
  "$EXP1/scripts/prepare-live-tools.sh"
  "$EXP1/scripts/verify-trusted-handoff.sh"
  "$EXP1/scripts/verify-workload-identity.sh"
  "$EXP1/scripts/verify-live-broker.sh"
  "$EXP1/scripts/verify-live-lifecycle.sh"
  "$EXP3/scripts/verify-composition.sh"
  "$EXP4/scripts/verify-support-semantics.sh"
  "$EXP5/scripts/verify-material-isolation.sh"
  "$EXP6/scripts/verify-multiple-consumers.sh"
  "$EXP7/scripts/verify-workspace.sh"
  "$EXP7/scripts/verify-sidecar.sh"
  "$EXP8/scripts/verify-lifecycle.sh"
  "$EXP9/scripts/verify-engine.sh"
  "$EXP10/scripts/verify-distribution.sh"
)

if grep -n -E 'coder exp sync|module\.pade|modules/rc-pade-bindings' "${integration_scripts[@]}"; then
  echo "Coder-specific orchestration leaked into executable Dev Container integration" >&2
  exit 1
fi

grep -q '43226ef96ae09419b6253a6eb364fd44a0ac1305' "$EXP1/README.md"
grep -q 'github.repo.read,github.repo.write' "$EXP1/fixtures/allow-capabilities.txt"
grep -q 'kind: source_control' "$EXP1/fixtures/verified-profile.yaml"
grep -q 'provider: github' "$EXP1/fixtures/verified-profile.yaml"
grep -q '53fe0bca5664c9b889304c881d6643cec163f449a9d02a91fd5a6d635ad62e19' "$EXP1/README.md"
grep -q 'TOCTOU\|tamper-resistant\|orchestration ordering' "$EXP1/README.md"

grep -q '853eab3c2c04f9d1059b2dbd64ea91996828a3a9' "$EXP3/README.md"
grep -q 'required: false' "$EXP4/README.md"
grep -q 'unsupported + optional' "$EXP4/README.md"

grep -q '05fb036' "$EXP5/README.md"
grep -q 'keeper://pade-demo-github' "$EXP5/fixtures/bindings.yaml"
grep -q 'github.repo.read' "$EXP6/fixtures/pade.yaml"
grep -q 'github.repo.write' "$EXP6/fixtures/pade.yaml"

grep -q 'dockerComposeFile' "$EXP7/.devcontainer/devcontainer.json"
grep -q 'SIDECAR_MARKER' "$EXP7/.devcontainer/docker-compose.yml"
grep -q 'postStartCommand' "$ROOT/src/pade/devcontainer-feature.json"
grep -q 'pade-exp008-state' "$ROOT/.devcontainer/experiments/008/devcontainer.json"

grep -q './features/pade' "$ROOT/.devcontainer/experiments/009/devcontainer.json"
grep -q -- '--docker-path' "$EXP9/scripts/verify-engine.sh"
grep -q 'features publish' "$EXP10/scripts/verify-distribution.sh"
grep -q 'pade@' "$EXP10/scripts/verify-distribution.sh"
grep -q 'published_digest=' "$EXP10/scripts/verify-distribution.sh"

# Provenance contract: YAML structure, experiment IDs, status fields, no obvious secrets.
python3 - "$PROV_CODER" <<'PY'
import pathlib
import re
import sys
import yaml

prov = pathlib.Path(sys.argv[1])
expected = {f"{i:03d}" for i in range(1, 11)}
found = set()
secret_patterns = [
    re.compile(r"Authorization:\s*Bearer\s+\S+", re.I),
    re.compile(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"),
    re.compile(r"GITHUB_TOKEN="),
    re.compile(r"KSM_CONFIG="),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----"),
    re.compile(r"pade-broker-\d+\.[a-z0-9-]+\.run\.app"),
]

for path in sorted(prov.glob("*.yaml")):
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    assert isinstance(data, dict), path
    exp = str(data.get("experiment", ""))
    status = str(data.get("status", ""))
    assert exp in expected, (path, exp)
    assert status in {"pass", "fail", "in_progress"}, (path, status)
    assert data.get("host") == "coder", (path, data.get("host"))
    found.add(exp)
    text = path.read_text(encoding="utf-8")
    for pat in secret_patterns:
        assert not pat.search(text), f"secret-like pattern in {path}: {pat.pattern}"
    print(f"provenance_ok={path.name} experiment={exp} status={status}")

missing = expected - found
assert not missing, missing
print("provenance_contract=pass")
PY

if [[ -e "$EXP1/fixtures/handoff/signer.key" ]]; then
  echo "private signing key must not be present under fixtures/handoff/" >&2
  exit 1
fi

grep -q 'Coder-hosted provenance' "$ROOT/experiments/README.md"
grep -q 'Complete' "$EXP1/README.md"

echo "repository_contract=pass"
