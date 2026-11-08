# Experiments

Sequential portability proofs for PADE in standard Dev Containers.

| ID | Directory | Question | Status |
|---|---|---|---|
| 001 | [001-verified-rc-pade](001-verified-rc-pade/) | Can a standard Dev Container consume verified Runtime Conditions demand through rc-pade bind and PADE without Coder-specific lifecycle machinery? | In progress; deterministic Dev Container CI smoke proven |
| 002 | [002-devcontainer-feature](002-devcontainer-feature/) | Can the lifecycle adapter be packaged as a native reusable Feature without absorbing RC/PADE semantics? | Complete; Feature CI proof passed |
| 003 | [003-composed-demand](003-composed-demand/) | Can real RC composition add Dev Container-only demand without mutating the application Profile? | Complete; pinned rc-demos composition proof passed |
| 004 | [004-support-semantics](004-support-semantics/) | What does current rc-pade do for supported/unsupported required and optional demand? | Complete with finding; optional unsupported demand currently fails closed |
| 005 | [005-material-isolation](005-material-isolation/) | Can PADE Material remain process-scoped inside a standard Dev Container? | Complete; process-scoped Material CI proof passed |
| 006 | [006-multiple-consumers](006-multiple-consumers/) | Can separate processes request distinct capabilities without ambient cross-leakage? | Complete; independent multi-consumer CI proof passed |
| 007 | [007-multi-container](007-multi-container/) | Does process-scoped Material remain isolated from sibling Compose services? | Complete; Compose sibling isolation CI proof passed |
| 008 | [008-lifecycle-stale-state](008-lifecycle-stale-state/) | Are stale bindings cleared on restart and fresh recreation with persistent state? | Complete; restart/recreate stale-state CI proof passed |
| 009 | [009-container-engine-portability](009-container-engine-portability/) | Does the same Feature lifecycle work unchanged through Docker and Podman? | Implemented; CI evidence pending |
| 010 | [010-oci-feature-distribution](010-oci-feature-distribution/) | Can the Feature be packaged, published to OCI, and consumed by digest without local source? | Implemented; CI evidence pending |

Experiments should preserve the architecture boundaries rather than optimizing for a positive result. Failures that expose environment-specific assumptions are useful evidence.
