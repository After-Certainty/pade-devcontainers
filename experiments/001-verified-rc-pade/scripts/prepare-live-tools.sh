#!/usr/bin/env bash
# Host-side: build pinned rc-pade + verify-handoff, stage Feature, materialize live broker binding.
# Does not commit secrets. Live broker URL is written only under gitignored .work/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORK="$ROOT/.work"
EXP1="$ROOT/experiments/001-verified-rc-pade"
STAGED_FEATURE="$ROOT/.devcontainer/experiments/001/features/pade"
RC_PADE_COMMIT="${RC_PADE_COMMIT:-43226ef96ae09419b6253a6eb364fd44a0ac1305}"
RC_DEMOS_REF="${RC_DEMOS_REF:-853eab3c2c04f9d1059b2dbd64ea91996828a3a9}"
GO_RC_PROFILER_REF="${GO_RC_PROFILER_REF:-5d2e860e48842b89ec83414123a7e59228f61d36}"
export PATH="${HOME}/sdk/go/bin:${PATH:-}"
export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"

mkdir -p "$WORK/bin" "$WORK/src" "$WORK/experiment-001"

# Stage Feature copy for local Dev Containers Feature resolution.
rm -rf "$STAGED_FEATURE"
mkdir -p "$STAGED_FEATURE"
cp "$ROOT/src/pade/devcontainer-feature.json" "$STAGED_FEATURE/devcontainer-feature.json"
cp "$ROOT/src/pade/install.sh" "$STAGED_FEATURE/install.sh"
chmod 0755 "$STAGED_FEATURE/install.sh"

# Prefer existing PADE v0.4.1 binary when present; else require .work/bin/pade.
if [[ ! -x "$WORK/bin/pade" ]]; then
  if [[ -x "${HOME}/.local/bin/pade" ]]; then
    cp "${HOME}/.local/bin/pade" "$WORK/bin/pade"
    chmod 0755 "$WORK/bin/pade"
  else
    echo "missing PADE binary at $WORK/bin/pade" >&2
    exit 1
  fi
fi
"$WORK/bin/pade" --version | tee "$WORK/experiment-001/pade-version.txt"

# Build pinned rc-pade.
if [[ ! -x "$WORK/bin/rc-pade" ]]; then
  mkdir -p "$WORK/src"
  curl -fsSL --retry 2 \
    -o "$WORK/rc-pade.tar.gz" \
    "https://github.com/After-Certainty/rc-pade/archive/${RC_PADE_COMMIT}.tar.gz"
  rm -rf "$WORK/src/rc-pade-"*
  tar -C "$WORK/src" -xzf "$WORK/rc-pade.tar.gz"
  RC_PADE_DIR="$(find "$WORK/src" -mindepth 1 -maxdepth 1 -type d -name 'rc-pade-*' | head -n1)"
  test -n "$RC_PADE_DIR"
  (
    cd "$RC_PADE_DIR"
    CGO_ENABLED=0 go build -trimpath -o "$WORK/bin/rc-pade" ./cmd/rc-pade
  )
fi
"$WORK/bin/rc-pade" bind --help >/dev/null

# Build verify-handoff against pinned rc-demos + go-rc-profiler when missing.
if [[ ! -x "$WORK/bin/verify-handoff" ]]; then
  VERIFY_WORK="$WORK/verify-handoff-build"
  mkdir -p "$VERIFY_WORK"
  if [[ ! -d "$VERIFY_WORK/rc-demos/.git" ]]; then
    git clone --depth 1 https://github.com/runtimeconditions/rc-demos.git "$VERIFY_WORK/rc-demos"
  fi
  git -C "$VERIFY_WORK/rc-demos" fetch --depth 1 origin "$RC_DEMOS_REF"
  git -C "$VERIFY_WORK/rc-demos" checkout --detach "$RC_DEMOS_REF"

  if [[ ! -d "$VERIFY_WORK/go-rc-profiler/.git" ]]; then
    git clone --depth 1 https://github.com/runtimeconditions/go-rc-profiler.git "$VERIFY_WORK/go-rc-profiler"
  fi
  git -C "$VERIFY_WORK/go-rc-profiler" fetch --depth 1 origin "$GO_RC_PROFILER_REF"
  git -C "$VERIFY_WORK/go-rc-profiler" checkout --detach "$GO_RC_PROFILER_REF"

  # Build from the pinned rc-demos module so replace paths match stock layout.
  # validated-profile-handoff go.mod replaces ../../go-rc-profiler → $VERIFY_WORK/go-rc-profiler.
  cp "$EXP1/scripts/verify-handoff/main.go" "$VERIFY_WORK/rc-demos/validated-profile-handoff/verify-handoff-main.go"
  (
    cd "$VERIFY_WORK/rc-demos/validated-profile-handoff"
    CGO_ENABLED=0 go build -trimpath -o "$WORK/bin/verify-handoff" ./verify-handoff-main.go
  )
fi
test -x "$WORK/bin/verify-handoff"

# Materialize live broker binding from operator environment / host config.
# Never prints endpoint values.
ROOT="$ROOT" python3 - <<'PY'
import json, os, pathlib, yaml

root = pathlib.Path(os.environ["ROOT"])
out = root / ".work" / "experiment-001" / "broker.live.json"
endpoint = os.environ.get("PADE_BROKER_ENDPOINT", "").strip()
audience = os.environ.get("PADE_BROKER_AUDIENCE", "").strip()
identity = os.environ.get("PADE_BROKER_IDENTITY", "gce").strip() or "gce"

if not endpoint:
    # Prefer explicit broker_binding.json from prior operator staging.
    candidates = [
        pathlib.Path.home() / ".config/pade/rc-downstream/broker_binding.json",
        pathlib.Path.home() / ".config/pade/coder-bindings.yaml",
    ]
    for path in candidates:
        if not path.is_file():
            continue
        if path.suffix == ".json":
            data = json.loads(path.read_text())
            broker = data.get("broker", data)
            endpoint = (broker.get("endpoint") or "").strip()
            audience = audience or (broker.get("audience") or "").strip()
            identity = (broker.get("identity") or identity).strip() or "gce"
            break
        data = yaml.safe_load(path.read_text()) or {}
        for cap in (data.get("capabilities") or {}).values():
            broker = (cap or {}).get("broker") or {}
            if broker.get("endpoint"):
                endpoint = str(broker["endpoint"]).strip()
                audience = audience or str(broker.get("audience") or "").strip()
                identity = str(broker.get("identity") or identity).strip() or "gce"
                break
        if endpoint:
            break

if not endpoint:
    raise SystemExit("PADE_BROKER_ENDPOINT unset and no host broker config found")

if not audience:
    audience = endpoint

payload = {
    "provider": "broker",
    "broker": {
        "endpoint": endpoint,
        "audience": audience,
        "identity": identity,
    },
}
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2) + "\n")
os.chmod(out, 0o600)
print(f"broker_live_materialized=true identity={identity} endpoint_recorded=false path={out}")
PY

# Copy allowlist/policy into work for live bind.
cp "$EXP1/fixtures/policy.yaml" "$WORK/experiment-001/policy.yaml"
cp "$EXP1/fixtures/allow-capabilities.txt" "$WORK/experiment-001/allow-capabilities.txt"

echo "prepare_live_tools=pass"
echo "rc_pade=$WORK/bin/rc-pade"
echo "pade=$WORK/bin/pade"
echo "verify_handoff=$WORK/bin/verify-handoff"
