#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXP="$ROOT/experiments/001-verified-rc-pade"

required=(
  "$ROOT/README.md"
  "$ROOT/experiments/README.md"
  "$EXP/README.md"
  "$ROOT/.devcontainer/devcontainer.json"
  "$EXP/fixtures/verified-profile.yaml"
  "$EXP/fixtures/policy.yaml"
  "$EXP/fixtures/allow-capabilities.txt"
  "$EXP/fixtures/broker.json"
  "$EXP/scripts/verify-bind.sh"
)

for path in "${required[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
done

python3 - "$ROOT/.devcontainer/devcontainer.json" "$EXP/fixtures/broker.json" <<'PY'
import json
import sys
for path in sys.argv[1:]:
    with open(path, "r", encoding="utf-8") as f:
        json.load(f)
    print(f"json_ok={path}")
PY

shellcheck "$ROOT/scripts/ci/verify-repository.sh" "$EXP/scripts/verify-bind.sh"

if grep -R -n -E 'coder exp sync|module\.pade|modules/rc-pade-bindings'   "$ROOT/.devcontainer" "$EXP/scripts"; then
  echo "Coder-specific orchestration leaked into executable Dev Container integration" >&2
  exit 1
fi

grep -q '43226ef96ae09419b6253a6eb364fd44a0ac1305' "$EXP/README.md"
grep -q 'github.repo.read,github.repo.write' "$EXP/fixtures/allow-capabilities.txt"
grep -q 'kind: source_control' "$EXP/fixtures/verified-profile.yaml"
grep -q 'provider: github' "$EXP/fixtures/verified-profile.yaml"

echo "experiment_001_repository_contract=pass"
