# Experiment 001 — verified Runtime Conditions → rc-pade bind → Dev Container

**Status:** Planned. This directory defines the first Dev Containers portability experiment and its deterministic CI harness. No live signed-handoff or broker provenance has been recorded yet.

## Question

Can a standard Dev Container consume a composed and trusted Runtime Conditions Profile, invoke the same reusable rc-pade bind boundary proven in Coder, and use PADE capabilities without any Coder-specific lifecycle machinery?

Target architecture:

~~~
application source + dev-container source
        ↓
Runtime Conditions composition
        ↓
composed Profile
        ↓
resolve + validate
        ↓
trusted handoff
        ↓
verified Profile
        ↓
Dev Container lifecycle integration
        ↓
rc-pade bind
        ↓
PADE Consumer bindings
        ↓
PADE Consumer
        ↓
broker authorization + fulfillment
~~~

## Why this experiment exists

The Coder experiments proved the individual architecture boundaries and then dogfooded the cleaned-up path:

~~~
signed handoff
  → verified Profile
  → environment lifecycle adapter
  → rc-pade bind
  → PADE bindings
  → broker
~~~

The next falsifiability test is to replace **Coder** with a standard Dev Container while keeping the RC, rc-pade, and PADE boundaries unchanged.

If this requires new Coder-like semantics in rc-pade or PADE core, record that as a portability failure before adding them.

## Pinned starting points

Use these as the initial baseline:

- rc-pade bind: 43226ef96ae09419b6253a6eb364fd44a0ac1305
- composed dev-container Profile semantics: the runtimeconditions/rc-demos dev-container composition used by rc-pade Experiments 006–015
- PADE: v0.4.1 for the first live broker checkpoint unless deliberately updated and recorded

The checked-in CI fixture is the composed Profile/policy used by Experiment 015. It represents the **post-trust input boundary** only. Its presence in this repository is not evidence that CI cryptographically validated it.

## Invariants

### Runtime Conditions

Runtime Conditions owns portable demand and validation. The Dev Container integration must not reinterpret invalid demand as merely unsupported.

### rc-pade

rc-pade bind receives already-verified Profile bytes plus explicit operator policy, allowlist, and broker binding. It must remain independent of Dev Container lifecycle details.

### Dev Container integration

This repository owns environment-native lifecycle ordering, installation, local fail-closed bindings, and handoff between independently owned steps.

Do not copy Coder sync semantics. Use Dev Container lifecycle primitives or small environment-neutral scripts.

### PADE

Local bindings request capabilities. They do not grant them. The broker remains the authorization boundary.

## CI contract

GitHub CI is required to verify the deterministic part of this experiment.

The CI smoke path must:

1. build the pinned rc-pade revision;
2. start the checked-in .devcontainer/devcontainer.json through the Dev Containers CLI;
3. run the smoke script **inside** the container;
4. bind the composed Profile with the checked-in policy and broker-only fixture;
5. observe both github.repo.read and github.repo.write in the output;
6. verify bindings mode 0600;
7. verify no validator-specific validation-report.yaml is needed by rc-pade bind;
8. re-run with a deliberately insufficient allowlist;
9. require that failure to leave the bindings file as capabilities: {}.

CI must also fail if executable integration scripts introduce Coder-specific synchronization primitives.

### What CI does not prove

CI does not prove:

- that the Profile was cryptographically trusted upstream;
- that the Dev Container has a production workload identity;
- that a live PADE broker authorizes either capability;
- that provider Material is successfully fulfilled;
- a tamper-resistant / TOCTOU-free verifier → bind transfer.

Those belong to later live checkpoints.

## Checkpoint 1 — establish the native Dev Container lifecycle

Inspect the current Dev Container specification and choose the smallest native lifecycle shape for:

- PADE installation;
- rc-pade installation;
- trusted handoff verification;
- fail-closed bindings initialization;
- bind only after trust succeeds;
- PADE-dependent workload only after bind succeeds.

Record why the selected hooks are appropriate and which steps are restart/rebuild/recreate sensitive.

### Stop condition

If correct ordering requires inventing a generic synchronization subsystem comparable to Coder's, stop and record the gap before implementing one.

## Checkpoint 2 — deterministic CI smoke path

Make the checked-in CI contract pass on GitHub Actions.

Record:

- Dev Containers CLI version;
- image digest if practical;
- rc-pade pin;
- generated bindings hash/mode;
- successful mapped capability names;
- negative allowlist result and empty-bindings hash.

This checkpoint proves only the post-trust projection/binding and native-container execution path.

## Checkpoint 3 — trusted handoff inside the Dev Container lifecycle

Reuse the existing experimental signed Runtime Conditions handoff unless current upstream tooling provides a better compatible mechanism.

Requirements:

- trust verification occurs before rc-pade bind;
- only public verification trust is present;
- private signing key is absent;
- failed verification prevents bind;
- bindings remain empty on failure.

Keep the existing limitation explicit: if verification writes verified-profile.yaml and bind later re-opens it under the same user, that is an orchestration handoff, not a tamper-proof isolation boundary.

## Checkpoint 4 — live PADE broker authorization

Use a real Dev Container workload identity mechanism suitable for PADE.

Do not assume the GCE/Coder identity mechanism transfers.

For the existing source-control demand, attempt:

### github.repo.read

Expected if the selected subject is authorized:

- trusted handoff succeeds;
- rc-pade bind succeeds;
- broker binding exists;
- PADE broker authorizes;
- ordinary GitHub read succeeds only in the PADE child.

### github.repo.write

Preserve the current deny case if the chosen subject has the same policy boundary. If authorization policy differs for the new identity, record the actual outcome rather than forcing parity.

## Checkpoint 5 — fail-closed lifecycle

After a successful live run, break an upstream prerequisite:

- corrupt signed evidence; or
- make the pinned rc-pade install unavailable; or
- provide unsupported verified demand.

Expected:

- stale bindings are not reusable;
- final bindings remain empty;
- PADE-dependent workload does not continue as if authority exists;
- restoring the valid input regenerates bindings without manual editing.

## Checkpoint 6 — rebuild / recreate portability

Exercise at least:

- container restart;
- rebuild;
- fresh recreate.

Confirm the environment can reconstruct its integration from repository + trusted external inputs without manual file staging.

## Checkpoint 7 — claim boundary and next environment

Compare the Dev Container result to Coder Experiment 015.

A successful experiment should show that these remain unchanged:

~~~
verified Profile
  → rc-pade mapping
  → PADE binding contract
  → broker authorization
~~~

Only the **environment lifecycle adapter** should differ.

Record any remaining environment-specific assumptions before considering DevPod, Codespaces, or another consumer.

## Evidence hygiene

Never record:

- private signing keys;
- OIDC/JWT bearer tokens;
- GitHub tokens or Material values;
- cloud access keys or session tokens;
- numeric cloud subject identifiers when avoidable;
- Dev Container secrets.

Safe evidence includes public pins, image identifiers, hashes, file modes, capability names, lifecycle outcomes, and authorize/deny classifications.

## Success

Experiment 001 succeeds when a standard Dev Container can reproduce the same architecture boundary proven in Coder without importing Coder-specific orchestration:

~~~
trusted RC handoff
  → verified Profile
  → native Dev Container lifecycle
  → rc-pade bind
  → PADE Consumer bindings
  → PADE broker
~~~

with deterministic CI coverage for projection/binding and live provenance for trust, identity, authorization, fail-closed behavior, and fresh recreation.

## Suggested Cursor workflow

Work through this README checkpoint by checkpoint.

Start with **Checkpoint 1 only**. For each checkpoint:

1. inspect the current repository and upstream pinned implementations;
2. report assumptions that differ from this runbook;
3. propose the smallest native Dev Container change;
4. state the evidence and stop condition;
5. implement only after agreement;
6. record actual results before moving on.

Do not make the integration look like Coder merely because Coder was the first proven environment.
