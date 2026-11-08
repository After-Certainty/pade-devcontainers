# Experiment 008 — restart/recreate stale-state lifecycle

**Status:** Implemented in this PR; GitHub CI evidence pending.

## Question

Can the PADE Dev Container Feature prevent stale local bindings from surviving a container restart or fresh container recreation when the bindings path itself lives on a persistent volume?

## Why this experiment exists

Experiment 002 initially contributed fail-closed initialization only through `postCreateCommand`.

That is sufficient for first creation but is not a strong enough lifecycle boundary for a stopped/restarted container whose filesystem or mounted state can retain previous bindings.

Because `pade-devcontainers` owns environment lifecycle orchestration, this experiment adds the same fail-closed initialization to the native `postStartCommand`.

## Method

The experiment uses:

- a standard Ubuntu Dev Container;
- the local `src/pade` Feature;
- `PADE_BINDINGS_PATH=/pade-state/bindings.yaml`;
- a named Docker volume mounted at `/pade-state`.

CI executes:

1. first container creation;
2. writes deliberately stale capability state;
3. stops the container;
4. starts the Dev Container again and requires the same container to be reused;
5. verifies `postStartCommand` replaced stale state with mode-`0600` empty bindings;
6. writes stale state again;
7. deletes the container but retains the named volume;
8. recreates the Dev Container;
9. verifies the persisted stale state is again replaced with empty bindings.

## Expected invariant

Every start begins fail closed:

```text
persistent previous bindings
          ↓
Dev Container start
          ↓
pade-devcontainer-init
          ↓
version: "0.1"
capabilities: {}
mode 0600
```

A later trusted bind step may repopulate the file. Restarting the environment must not silently preserve that prior authority.

## Claim boundary

This proves stale local binding invalidation across stop/start reuse and fresh container recreation with persistent storage.

It does not prove automatic re-verification or re-binding after start. The experiment intentionally clears authority; a caller still owns the trusted handoff and subsequent `rc-pade bind` step.

It also does not yet prove migration across published Feature versions.
