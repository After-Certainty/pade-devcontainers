# Experiment 009 — container-engine portability

**Status:** Complete — GitHub CI proved the same Feature/config lifecycle on Docker and Podman through Dev Containers CLI 0.90.0.

## Question

Can the same PADE Dev Container Feature and fail-closed lifecycle run unchanged through the Dev Containers CLI when the underlying container engine changes from Docker to Podman?

## Why this experiment exists

Earlier experiments used Docker-backed GitHub runners. That proves the Dev Container architecture is not Coder-specific, but it can still accidentally depend on Docker behavior.

The Dev Containers CLI explicitly supports selecting another compatible engine with `--docker-path`. This experiment uses that native seam rather than adding an engine abstraction to PADE or Runtime Conditions.

## Method

Before each engine run, CI stages an exact copy of the maintained `src/pade` Feature beneath the repository root `.devcontainer` tree, as required for local Features.

The same `devcontainer.json` is then started with:

- Docker;
- Podman.

For each engine CI requires:

- the Dev Container starts successfully;
- `pade-devcontainer-init` and `pade-devcontainer-bind` are installed;
- native lifecycle initialization creates fail-closed `capabilities: {}`;
- the bindings file is mode `0600`;
- no engine-specific Feature source or PADE semantic configuration is used.

## Observed result

GitHub CI observed:

- Docker → Feature install passed; fail-closed bindings passed;
- Podman 4.9.3 → Feature install passed; fail-closed bindings passed;
- both used the same `devcontainer.json` and the same staged Feature bytes.

No PADE or Runtime Conditions semantic branch was introduced for either engine.

## Claim boundary

A passing result is **container-engine portability evidence**, not universal host portability.

It does not prove:

- GitHub Codespaces;
- DevPod;
- Docker Desktop on macOS/Windows;
- arbitrary Podman distributions;
- live Runtime Conditions trust or broker/provider authorization.

Those environments may still expose lifecycle or identity differences.

## Pins

- Dev Containers CLI: `0.90.0`
- Docker: GitHub-hosted runner version
- Podman: Ubuntu runner package version recorded by CI
