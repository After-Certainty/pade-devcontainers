# Experiment 010 — OCI Feature packaging and clean consumption

**Status:** Implemented in this PR; GitHub CI evidence pending.

## Question

Can the PADE Dev Container Feature be packaged, published to an OCI registry, and consumed by a clean Dev Container workspace using only the published Feature reference rather than repository-local Feature source?

## Why this experiment exists

Experiment 002 proved the integration can be represented as a Dev Container Feature, but consumers still depended on local source under `src/pade`.

A reusable integration needs a distribution boundary:

```text
maintained Feature source
        ↓
Dev Containers package/publish
        ↓
OCI artifact + digest
        ↓
clean consumer devcontainer.json
        ↓
Feature install + lifecycle
```

## Method

GitHub CI starts an ephemeral anonymous OCI registry on localhost.

It then uses the pinned Dev Containers CLI to:

1. package `src/pade`;
2. verify the generated Feature archive and collection metadata;
3. publish the collection to the disposable registry;
4. capture the canonical published digest for `pade`;
5. query the registry manifest through `devcontainer features info manifest`;
6. generate a clean workspace outside the repository's maintained Feature tree;
7. reference the Feature by **digest**, not a mutable tag;
8. start that clean Dev Container and verify the installed helpers and fail-closed bindings lifecycle.

## Assertions

The clean consumer:

- contains no copied `src/pade` Feature source;
- references only the OCI registry digest;
- installs `pade-devcontainer-init` and `pade-devcontainer-bind`;
- starts with mode-`0600` empty bindings.

The published manifest must use the Dev Container Feature layer media type.

## Claim boundary

This proves the Feature follows the OCI distribution path and can be consumed without repository-local source.

It does not publish a permanent public package, establish release signing, define a production update policy, or prove GHCR permissions/visibility. A disposable localhost registry is intentionally used so the experiment cannot accidentally become a release.

A later packaging hardening step can add a real public release workflow after versioning and binary-distribution policy are settled.

## Pins

- Dev Containers CLI: `0.90.0`
- Feature version: current `src/pade/devcontainer-feature.json`
