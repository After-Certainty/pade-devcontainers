#!/bin/sh
set -eu

install -d /usr/local/bin

cat >/usr/local/bin/pade-devcontainer-init <<'EOF'
#!/bin/sh
set -eu

bindings="${PADE_BINDINGS_PATH:-$HOME/.config/pade/devcontainer-bindings.yaml}"
directory=$(dirname "$bindings")
mkdir -p "$directory"

umask 077
tmp="$bindings.tmp.$$"
trap 'rm -f "$tmp"' EXIT HUP INT TERM
printf 'version: "0.1"\ncapabilities: {}\n' >"$tmp"
chmod 600 "$tmp"
mv "$tmp" "$bindings"
trap - EXIT HUP INT TERM

printf 'pade_devcontainer_bindings=%s\n' "$bindings"
EOF

cat >/usr/local/bin/pade-devcontainer-bind <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
  echo "usage: pade-devcontainer-bind VERIFIED_PROFILE POLICY BROKER_BINDING ALLOW_CAPABILITIES [SESSION_OUT]" >&2
  exit 2
fi

verified_profile=$1
policy=$2
broker_binding=$3
allow_capabilities=$4
session_out=${5:-}
bindings="${PADE_BINDINGS_PATH:-$HOME/.config/pade/devcontainer-bindings.yaml}"
rc_pade_bin="${RC_PADE_BIN:-rc-pade}"

pade-devcontainer-init >/dev/null

case "$bindings" in
  /*) ;;
  *)
    echo "PADE_BINDINGS_PATH must resolve to an absolute path: $bindings" >&2
    exit 2
    ;;
esac

if ! command -v "$rc_pade_bin" >/dev/null 2>&1 && [ ! -x "$rc_pade_bin" ]; then
  echo "rc-pade is unavailable: $rc_pade_bin" >&2
  exit 127
fi

set -- bind   --verified-profile "$verified_profile"   --policy "$policy"   --broker-binding "$broker_binding"   --allow-capabilities "$allow_capabilities"   --output "$bindings"

if [ -n "$session_out" ]; then
  set -- "$@" --session-out "$session_out"
fi

"$rc_pade_bin" "$@"
EOF

chmod 0755 /usr/local/bin/pade-devcontainer-init /usr/local/bin/pade-devcontainer-bind
