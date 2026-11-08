# pade-devcontainers

Portable Dev Container lifecycle integration for PADE.

This repository owns the **Dev Container environment integration** around PADE. It does not redefine Runtime Conditions semantics, rc-pade projection semantics, PADE authorization, or broker/provider behavior.

## Boundary

~~~
workload + dev-container sources
        ↓
Runtime Conditions generation / composition
        ↓
RuntimeConditionsProfile
        ↓
Runtime Conditions validation + trusted handoff
        ↓
verified Profile bytes
        ↓
rc-pade bind
  + operator ProjectionPolicy
  + operator capability allowlist
  + PADE broker binding
        ↓
PADE Consumer bindings
        ↓
Dev Container lifecycle
        ↓
PADE Consumer → broker → provider → Material
~~~

Ownership stays intentionally separated:

- **Runtime Conditions** owns portable demand, composition, and validation.
- **Trusted handoff** establishes confidence in the exact Profile accepted upstream.
- **rc-pade** owns platform support/mapping from already-verified RC demand to opaque PADE capabilities.
- **pade-devcontainers** owns Dev Container installation, lifecycle ordering, fail-closed local binding state, and environment-specific orchestration.
- **PADE** owns Consumer/Broker/Provider contracts, runtime identity, authorization, and fulfillment.

## Non-goals

This repository must not:

- add Runtime Conditions validation semantics to PADE;
- teach rc-pade about Dev Containers;
- copy Coder synchronization primitives into Dev Containers;
- treat an RC Condition as an authorization grant;
- embed durable provider credentials in the repository or generated bindings;
- standardize the experimental signed-handoff format used by earlier rc-pade experiments.

## Experiments

See [experiments/](experiments/).

The current experiment sequence is:

- **001** — prove the post-trust rc-pade binding path executes inside a standard Dev Container.
- **002** — package the environment lifecycle adapter as a reusable native Dev Container Feature.
- **003** — run the real Runtime Conditions composer and keep application demand separate from wrapper-owned Dev Container demand.
- **004** — make required/optional and supported/unsupported behavior observable at the rc-pade platform-support boundary.
- **005** — verify PADE Material is injected only into explicitly scoped child processes.
- **006** — verify multiple processes can request independent capability sets without making Material ambient to the container.
- **007** — verify a Compose-backed Dev Container keeps PADE Material out of sibling services.
- **008** — verify restart/recreate lifecycle clears stale bindings even when the bindings path persists.

## CI

GitHub Actions verifies the deterministic part of Experiment 001 on every push and pull request:

1. repository/experiment contract checks;
2. build the pinned rc-pade revision;
3. start the repository with the Dev Containers CLI;
4. run rc-pade bind inside that Dev Container against the composed dev-container Profile fixture;
5. verify the expected GitHub read/write broker bindings;
6. exercise an allowlist failure and confirm bindings are replaced with capabilities: {}.

Additional CI jobs demonstrate Experiments 002–008 independently: Feature tests, real RC composition, support/optionality behavior, process-scoped Material isolation, independent consumers, Compose sibling isolation, and restart/recreate stale-state handling.

CI deliberately does **not** claim to prove the later live checkpoints: signed-handoff trust, cloud workload identity, broker authorization, or provider fulfillment. Those require explicit provenance from the live experiment.
