# Experiment 003 — application + dev-container demand composition

**Status:** Complete — the real pinned rc-demos composer passed in GitHub CI; the application Profile remained byte-identical and composition provenance assertions passed.

## Question

Can the actual Runtime Conditions dev-container composer materialize environment-owned source-control demand without mutating the application Profile or changing the application's workload identity?

## Pinned implementation

Runtime Conditions demo:

`runtimeconditions/rc-demos@853eab3c2c04f9d1059b2dbd64ea91996828a3a9`

The CI job runs the real `dev-container-profile/cmd/profile-compose` implementation from that revision.

## Expected evidence

The input application Profile:

- workload URI remains the application URI;
- contains `content-api` and `site-analytics`;
- does not contain `application-source`.

The composed Dev Container Profile:

- gets the recipe's distinct Dev Container workload URI;
- retains `content-api` and `site-analytics`;
- adds wrapper-owned `application-source`;
- contains the wrapper source-control extension;
- records application and wrapper contributions in a separate provenance artifact.

CI also hashes the application Profile before and after composition and requires the bytes to be unchanged.

## Observed result

The CI run produced a composed Profile with `content-api`, `site-analytics`, and wrapper-owned `application-source`, while the input application Profile retained only its application-owned Conditions and its original workload URI. The application Profile SHA-256 before and after composition was:

`1175152793691ad5812b873019adb18f3f98eeb68cdd7a7670c137c2ad298c4e`

The separate composition provenance attributed `content-api` and `site-analytics` to the application Profile and `application-source` to wrapper additions.

## Claim boundary

This experiment tests composition, not Runtime Conditions validation or trusted handoff. It uses the already-established upstream composition implementation and its authoring artifacts.

Success supports this boundary:

```text
application demand
     remains application-owned
             +
dev-container-only demand
             ↓
separate composed Dev Container Profile
```

It does not imply that wrapper requirements belong in the application Profile.
