# Experiment 003 — application + dev-container demand composition

**Status:** Implemented in this PR; GitHub CI evidence pending.

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
