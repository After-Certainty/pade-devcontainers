# Experiment 007 — multi-container Dev Container topology

**Status:** Implemented in this PR; GitHub CI evidence pending.

## Question

When a Dev Container uses Docker Compose with a workspace service and a sibling service, does PADE Material remain scoped to an explicitly selected process in the workspace container rather than becoming ambient state shared with sibling containers?

## Topology

```text
Compose project
  ├── workspace
  │     ├── ordinary shell      → no Material
  │     └── pade exec child     → selected Material
  └── sidecar                  → no Material, no workspace mount
```

The workspace and sidecar share the Compose network but have different filesystem mounts and environment configuration.

## Method

GitHub Actions starts the experiment through the Dev Containers CLI using the checked-in Compose-backed devcontainer configuration.

PADE v0.4.1 runs only from the workspace mount and uses its built-in fake Keeper Secrets Manager path to materialize a synthetic GitHub token for one child process.

The sidecar is inspected separately through Docker using the Compose project identity returned by `devcontainer up`.

## Assertions

Workspace service:

- has no ambient `GITHUB_TOKEN`;
- does not inherit the sidecar-only environment marker;
- can materialize the synthetic token only inside an explicit `pade exec` child;
- returns to no ambient token after the child exits.

Sidecar service:

- has its own sidecar marker;
- has no `GITHUB_TOKEN`;
- has no PADE executable;
- does not have the repository workspace mounted.

## Claim boundary

This proves that PADE process-scoped Material in the workspace service does not become Compose-level or sibling-container ambient state in this topology.

It does not prove hostile-container network isolation, kernel-level isolation, or live broker/provider authorization.

## Pins

- PADE v0.4.1: `05fb0361c8af17c2031b2e3815d252d9cc49bdf7`
- Dev Containers CLI: `0.90.0`
