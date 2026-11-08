# Experiment 002 — reusable Dev Container Feature

**Status:** Complete — reusable Feature CI proof passed on Ubuntu 24.04 and Debian bookworm-slim with Dev Containers CLI 0.90.0.

## Question

Can the Dev Container-specific lifecycle behavior proven in Experiment 001 be packaged as a reusable native Dev Container Feature without moving Runtime Conditions semantics, rc-pade mapping, or PADE authorization into the Feature?

## Hypothesis

A Feature can own only the environment integration:

- initialize the local PADE bindings path fail closed;
- expose a small helper that invokes caller-owned `rc-pade bind`;
- contribute initialization through the native Dev Container lifecycle.

The Feature should not own the verified Profile producer, trusted handoff, operator policy, rc-pade installation, PADE installation, broker authorization, or provider fulfillment.

## Implementation under test

Feature source:

`src/pade/`

The Feature contributes:

`postCreateCommand: pade-devcontainer-init`

and installs:

- `pade-devcontainer-init`
- `pade-devcontainer-bind`

The default bindings target is `$HOME/.config/pade/devcontainer-bindings.yaml`. A caller may override it with `PADE_BINDINGS_PATH`.

## CI proof

GitHub Actions runs the official Dev Containers Feature test command against multiple Debian-family base images:

`devcontainer features test -f pade ...`

The test requires:

1. both helpers are installed;
2. the Feature does not silently install `rc-pade`;
3. initialization produces mode-`0600` `capabilities: {}`;
4. stale bindings are replaced before a bind attempt;
5. if caller-owned `rc-pade` is unavailable, bind fails and the local bindings remain empty.

## Observed result

GitHub CI successfully installed and exercised the local `pade` Feature on both tested base images. The native `postCreateCommand` initialized the default fail-closed bindings path, the test override produced the same empty mode-`0600` state, and an attempted bind without caller-owned `rc-pade` failed without preserving stale authority.

## What success proves

Success demonstrates that the environment lifecycle adapter can be distributed as a standard Dev Container Feature and remain separate from rc-pade/PADE semantics.

It does **not** prove Feature publication to GHCR, production binary distribution, trusted RC handoff, workload identity, or broker/provider behavior.
