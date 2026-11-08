# Experiment 005 — process-scoped Material isolation

**Status:** Implemented in this PR; GitHub CI evidence pending.

## Question

Inside a standard Dev Container, can PADE materialize credential-like data for one `pade exec` child without placing that Material in the ordinary container environment, portable intent, local binding configuration, or later sibling processes?

## Method

This experiment pins PADE v0.4.1 and uses its built-in Keeper Secrets Manager fake mode. The fake provider returns a synthetic `GITHUB_TOKEN` value only during capability resolution.

The checked-in files contain:

- portable PADE Intent declaring `github.repo.read`;
- a local provider binding containing only a Keeper notation reference;
- no resolved token value.

CI runs the experiment **inside the standard Dev Container**.

## Assertions

Before PADE execution:

- the ordinary shell has no `GITHUB_TOKEN`;
- PID 1's container environment has no `GITHUB_TOKEN`;
- neither the manifest nor bindings file contains the synthetic resolved token.

During `pade exec`:

- the selected child receives the expected synthetic `GITHUB_TOKEN`;
- a synthetic `KSM_CONFIG` bootstrap value supplied only to PADE is stripped from the child;
- if the child prints the exact resolved token, PADE redacts it before it reaches CI output.

After the child exits:

- the ordinary shell still has no `GITHUB_TOKEN`;
- a subsequent ordinary child has no `GITHUB_TOKEN`;
- bindings remain configuration-only and contain no Material.

## Claim boundary

This proves the reference Consumer's **process-scoped injection boundary** in a Dev Container using synthetic local provider Material.

It does not prove that a malicious child cannot observe or exfiltrate credentials intentionally. A process that receives Material can use it.

It also does not prove live Keeper, broker, workload-identity, expiration, revocation, or provider-side isolation.

## Pinned runtime

PADE v0.4.1:

`05fb036`

Go toolchain:

`1.26.10`
