# PADE Dev Container Integration Feature

This experimental Feature packages the **Dev Container lifecycle adapter**, not Runtime Conditions semantics and not PADE authorization.

It installs two helpers:

- `pade-devcontainer-init`: atomically replaces the local PADE bindings path with a mode-`0600` empty binding set.
- `pade-devcontainer-bind`: initializes fail-closed state, then invokes caller-owned `rc-pade bind` with a verified Profile, operator policy, allowlist, and broker binding.

The Feature contributes `pade-devcontainer-init` as a native `postCreateCommand`.

## Deliberate boundary

This first Feature experiment does **not** install `rc-pade` or PADE itself. Binary distribution is a separate concern and remains caller-owned until checksum-pinned release packaging exists.

It also does not:

- validate Runtime Conditions;
- define the trusted handoff;
- embed operator mapping policy;
- grant capabilities;
- copy Coder synchronization concepts.

The default local bindings path is:

`$HOME/.config/pade/devcontainer-bindings.yaml`

Set `PADE_BINDINGS_PATH` at runtime to override it.
