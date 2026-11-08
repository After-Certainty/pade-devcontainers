# Experiments

Sequential portability proofs for PADE in standard Dev Containers.

Evidence is recorded in three complementary ways:

1. **Canonical status** — the Status column below (experiment meaning and findings).
2. **GitHub CI evidence** — deterministic workflows on `ubuntu-latest` (see `.github/workflows/`).
3. **Coder-hosted provenance** — additional execution from the GCE-backed Coder outer host under [`provenance/coder-2026-11-08/`](provenance/coder-2026-11-08/).

Coder is the outer host used to run standard Dev Containers. It is not part of the Dev Container integration contract.

| ID | Directory | Question | Status | Coder provenance |
|---|---|---|---|---|
| 001 | [001-verified-rc-pade](001-verified-rc-pade/) | Can a standard Dev Container consume verified Runtime Conditions demand through rc-pade bind and PADE without Coder-specific lifecycle machinery? | Complete; CI smoke + live trust/identity/broker path proven from Coder host | [001.yaml](provenance/coder-2026-11-08/001.yaml) |
| 002 | [002-devcontainer-feature](002-devcontainer-feature/) | Can the lifecycle adapter be packaged as a native reusable Feature without absorbing RC/PADE semantics? | Complete; Feature CI proof passed | [002.yaml](provenance/coder-2026-11-08/002.yaml) |
| 003 | [003-composed-demand](003-composed-demand/) | Can real RC composition add Dev Container-only demand without mutating the application Profile? | Complete; pinned rc-demos composition proof passed | [003.yaml](provenance/coder-2026-11-08/003.yaml) |
| 004 | [004-support-semantics](004-support-semantics/) | What does current rc-pade do for supported/unsupported required and optional demand? | Complete with finding; optional unsupported demand currently fails closed | [004.yaml](provenance/coder-2026-11-08/004.yaml) |
| 005 | [005-material-isolation](005-material-isolation/) | Can PADE Material remain process-scoped inside a standard Dev Container? | Complete; process-scoped Material CI proof passed | [005.yaml](provenance/coder-2026-11-08/005.yaml) |
| 006 | [006-multiple-consumers](006-multiple-consumers/) | Can separate processes request distinct capabilities without ambient cross-leakage? | Complete; independent multi-consumer CI proof passed | [006.yaml](provenance/coder-2026-11-08/006.yaml) |
| 007 | [007-multi-container](007-multi-container/) | Does process-scoped Material remain isolated from sibling Compose services? | Complete; Compose sibling isolation CI proof passed | [007.yaml](provenance/coder-2026-11-08/007.yaml) |
| 008 | [008-lifecycle-stale-state](008-lifecycle-stale-state/) | Are stale bindings cleared on restart and fresh recreation with persistent state? | Complete; restart/recreate stale-state CI proof passed | [008.yaml](provenance/coder-2026-11-08/008.yaml) |
| 009 | [009-container-engine-portability](009-container-engine-portability/) | Does the same Feature lifecycle work unchanged through Docker and Podman? | Complete; Docker and Podman engine CI proof passed | [009.yaml](provenance/coder-2026-11-08/009.yaml) |
| 010 | [010-oci-feature-distribution](010-oci-feature-distribution/) | Can the Feature be packaged, published to OCI, and consumed by digest without local source? | Complete; digest-pinned OCI distribution CI proof passed | [010.yaml](provenance/coder-2026-11-08/010.yaml) |

Experiments should preserve the architecture boundaries rather than optimizing for a positive result. Failures that expose environment-specific assumptions are useful evidence.

Coder provenance for 002–010 is **additional execution evidence** only; it does not rewrite historical CI results. Experiment 009’s Coder run notes that Podman was installed on the host but rootless Feature builds failed due to cgroup/systemd linger constraints; Docker passed.
