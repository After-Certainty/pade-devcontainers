#!/usr/bin/env bash
# Host orchestrator for Experiment 001 live path: create → trust/bind → identity → broker
# → corrupt/recover → restart → recreate.
# Coder is the outer host only; Dev Container lifecycle uses native CLI primitives.
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONFIG="$ROOT/.devcontainer/experiments/001/devcontainer.json"
STAGED_FEATURE="$ROOT/.devcontainer/experiments/001/features/pade"
WORK="$ROOT/.work/experiment-001"
SCRIPTS="$ROOT/experiments/001-verified-rc-pade/scripts"
RESULT="$WORK/lifecycle-result.txt"

export PATH="/usr/local/bin:${HOME}/sdk/go/bin:/usr/local/lib/nodejs/current/bin:${PATH:-}"

mkdir -p "$WORK"

docker_cmd() {
  sg docker -c "docker $(printf '%q ' "$@")"
}

cleanup() {
  if [[ -n "${last_container:-}" ]]; then
    docker_cmd rm -f "$last_container" >/dev/null 2>&1 || true
  fi
  # Keep staged feature for inspection on failure; remove on success path below.
}
trap cleanup EXIT

stage_feature() {
  rm -rf "$STAGED_FEATURE"
  mkdir -p "$STAGED_FEATURE"
  cp "$ROOT/src/pade/devcontainer-feature.json" "$STAGED_FEATURE/devcontainer-feature.json"
  cp "$ROOT/src/pade/install.sh" "$STAGED_FEATURE/install.sh"
  chmod 0755 "$STAGED_FEATURE/install.sh"
}

container_id() {
  python3 -c 'import json,sys; print(json.load(sys.stdin)["containerId"])'
}

active_config() {
  if [[ "${PADE_EXP001_NETWORK:-}" == "host" ]]; then
    printf '%s\n' "$WORK/devcontainer.hostnet.json"
  else
    printf '%s\n' "$CONFIG"
  fi
}

ensure_hostnet_config() {
  python3 - <<PY
import json, pathlib
src = pathlib.Path("$CONFIG")
dst = pathlib.Path("$WORK/devcontainer.hostnet.json")
data = json.loads(src.read_text())
data["runArgs"] = ["--network=host"]
dst.write_text(json.dumps(data, indent=2) + "\n")
PY
}

up() {
  local cfg
  if [[ "${PADE_EXP001_NETWORK:-}" == "host" ]]; then
    ensure_hostnet_config
  fi
  cfg="$(active_config)"
  # Run under docker group without nested argv mangling.
  sg docker -c "devcontainer up --workspace-folder $(printf %q "$ROOT") --config $(printf %q "$cfg")"
}

dexec() {
  local cfg
  cfg="$(active_config)"
  # Write argv to a temp script on the bind-mounted workspace; exec via container path.
  local cmd_file="$WORK/dexec-cmd.sh"
  local cmd_file_in_container="/workspaces/pade-devcontainers/.work/experiment-001/dexec-cmd.sh"
  {
    printf '#!/bin/bash\nset -euo pipefail\ncd /workspaces/pade-devcontainers\n'
    printf 'export PATH="/workspaces/pade-devcontainers/.work/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"\n'
    printf 'export RC_PADE_BIN="/workspaces/pade-devcontainers/.work/bin/rc-pade"\n'
    printf 'export PADE_BIN="/workspaces/pade-devcontainers/.work/bin/pade"\n'
    printf 'export VERIFY_HANDOFF_BIN="/workspaces/pade-devcontainers/.work/bin/verify-handoff"\n'
    printf 'export PADE_BINDINGS_PATH="/tmp/pade-exp001/bindings.yaml"\n'
    printf 'export PADE_BROKER_LIVE="/workspaces/pade-devcontainers/.work/experiment-001/broker.live.json"\n'
    printf 'exec'
    local arg
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
  } >"$cmd_file"
  chmod 0755 "$cmd_file"
  sg docker -c "devcontainer exec --workspace-folder $(printf %q "$ROOT") --config $(printf %q "$cfg") bash $cmd_file_in_container"
}

echo "== prepare live tools =="
bash "$SCRIPTS/prepare-live-tools.sh"

stage_feature

echo "== first create =="
first_json="$(up)"
first_id="$(printf '%s' "$first_json" | container_id)"
last_container="$first_id"
echo "container_id_first_len=${#first_id}"

# Ensure curl/python exist inside the container for probes.
dexec bash -lc 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq curl ca-certificates python3 >/dev/null'

echo "== trusted handoff + bind + negative =="
dexec bash experiments/001-verified-rc-pade/scripts/verify-trusted-handoff.sh

echo "== workload identity =="
set +e
dexec bash experiments/001-verified-rc-pade/scripts/verify-workload-identity.sh
ID_RC=$?
set -e
if [[ "$ID_RC" -eq 2 && "${PADE_EXP001_NETWORK:-}" != "host" ]]; then
  echo "metadata unreachable on default network; retrying with documented host-network tweak"
  docker_cmd rm -f "$first_id" >/dev/null 2>&1 || true
  last_container=""
  export PADE_EXP001_NETWORK=host
  stage_feature
  first_json="$(up)"
  first_id="$(printf '%s' "$first_json" | container_id)"
  last_container="$first_id"
  dexec bash -lc 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq curl ca-certificates python3 >/dev/null'
  dexec bash experiments/001-verified-rc-pade/scripts/verify-trusted-handoff.sh
  set +e
  dexec bash experiments/001-verified-rc-pade/scripts/verify-workload-identity.sh
  ID_RC=$?
  set -e
  if [[ "$ID_RC" -ne 0 ]]; then
    echo "workload identity still unavailable with host network rc=$ID_RC" >&2
    echo "identity_blocked=true" | tee "$WORK/identity-blocked.txt"
    cat >"$RESULT" <<EOF
status=in_progress
blocker=workload_identity_unreachable_from_devcontainer
identity_network_mode=host
restart=not_run
recreate=not_run
live_broker=not_run
EOF
    exit 3
  fi
  echo "identity_network_mode=host" | tee "$WORK/identity-network-mode.txt"
elif [[ "$ID_RC" -ne 0 ]]; then
  echo "workload identity probe failed rc=$ID_RC" >&2
  echo "identity_blocked=true" | tee "$WORK/identity-blocked.txt"
  # Do not fake broker success when identity is unavailable.
  cat >"$RESULT" <<EOF
status=in_progress
blocker=workload_identity_unreachable_from_devcontainer
restart=not_run
recreate=not_run
live_broker=not_run
EOF
  exit 3
else
  if [[ "${PADE_EXP001_NETWORK:-}" == "host" ]]; then
    echo "identity_network_mode=host" | tee "$WORK/identity-network-mode.txt"
  else
    echo "identity_network_mode=default" | tee "$WORK/identity-network-mode.txt"
  fi
fi

echo "== live broker authorization =="
dexec bash experiments/001-verified-rc-pade/scripts/verify-live-broker.sh

echo "== restart (stop/start same container) =="
docker_cmd stop "$first_id" >/dev/null
restart_json="$(up)"
restart_id="$(printf '%s' "$restart_json" | container_id)"
last_container="$restart_id"
if [[ "$restart_id" != "$first_id" ]]; then
  echo "expected restart to reuse container id" >&2
  exit 1
fi
# postStart clears bindings; re-verify + re-bind + live auth.
dexec bash experiments/001-verified-rc-pade/scripts/verify-trusted-handoff.sh
dexec bash experiments/001-verified-rc-pade/scripts/verify-workload-identity.sh
dexec bash experiments/001-verified-rc-pade/scripts/verify-live-broker.sh
echo "restart=pass"

echo "== fresh recreate =="
docker_cmd rm -f "$restart_id" >/dev/null
last_container=""
# Intentionally persistent inputs: checked-in public handoff + .work broker.live.json + tools.
recreate_json="$(up)"
recreate_id="$(printf '%s' "$recreate_json" | container_id)"
last_container="$recreate_id"
if [[ "$recreate_id" == "$first_id" ]]; then
  echo "expected recreate to allocate a new container" >&2
  exit 1
fi
dexec bash -lc 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq curl ca-certificates python3 >/dev/null'
dexec bash experiments/001-verified-rc-pade/scripts/verify-trusted-handoff.sh
dexec bash experiments/001-verified-rc-pade/scripts/verify-workload-identity.sh
dexec bash experiments/001-verified-rc-pade/scripts/verify-live-broker.sh
echo "recreate=pass"

cat >"$RESULT" <<EOF
status=pass
identity_network_mode=${PADE_EXP001_NETWORK:-default}
restart=pass
recreate=pass
live_broker=pass
trusted_handoff=pass
EOF

# Cleanup containers to reclaim disk; keep .work evidence.
docker_cmd rm -f "$recreate_id" >/dev/null 2>&1 || true
last_container=""
rm -rf "$STAGED_FEATURE"
sg docker -c 'docker image prune -f' >/dev/null 2>&1 || true

echo "experiment_001_live_lifecycle=pass"
