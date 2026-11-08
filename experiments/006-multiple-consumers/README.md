# Experiment 006 — independent capability consumers

**Status:** Implemented in this PR; GitHub CI evidence pending.

## Question

Can multiple processes in the same Dev Container request different PADE capabilities independently, such that each child receives only the Material for the capability it explicitly selects?

## Method

PADE v0.4.1 runs with two synthetic Keeper Secrets Manager bindings:

- `github.repo.read` → `GITHUB_READ_TOKEN`;
- `github.repo.write` → `GITHUB_WRITE_TOKEN`.

The fake Keeper records resolve to distinct synthetic values. Nothing is placed in the ordinary container environment.

CI executes three children:

1. **read consumer** requests only `github.repo.read`;
2. **write consumer** requests only `github.repo.write`;
3. **combined consumer** explicitly requests both.

## Assertions

The read child must:

- receive `GITHUB_READ_TOKEN`;
- not receive `GITHUB_WRITE_TOKEN`.

The write child must:

- receive `GITHUB_WRITE_TOKEN`;
- not receive `GITHUB_READ_TOKEN`.

The combined child must receive both only because both capabilities were explicitly requested.

Before and after all three executions, the ordinary Dev Container shell must have neither token.

## Why this matters

This distinguishes PADE from "put credentials into the development container":

```text
container
  ├── ordinary shell           → no Material
  ├── read consumer            → github.repo.read only
  ├── write consumer           → github.repo.write only
  └── explicitly combined task → read + write
```

Capability selection is per execution, not ambient container state.

## Claim boundary

This experiment proves independent capability selection and process-scoped synthetic Material in the reference Consumer.

It does not prove that two simultaneously running mutually hostile processes are OS-sandboxed from one another, nor does it prove live broker policy. It also does not imply that write authority should always be separately granted; the bindings are synthetic test configuration.

## Pinned runtime

PADE v0.4.1:

`05fb036`
