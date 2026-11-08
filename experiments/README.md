# Experiments

Sequential portability proofs for PADE in standard Dev Containers.

| ID | Directory | Question | Status |
|---|---|---|---|
| 001 | [001-verified-rc-pade](001-verified-rc-pade/) | Can a standard Dev Container consume verified Runtime Conditions demand through rc-pade bind and PADE without Coder-specific lifecycle machinery? | In progress; deterministic Dev Container CI smoke proven |
| 002 | [002-devcontainer-feature](002-devcontainer-feature/) | Can the lifecycle adapter be packaged as a native reusable Feature without absorbing RC/PADE semantics? | Complete; Feature CI proof passed |
| 003 | [003-composed-demand](003-composed-demand/) | Can real RC composition add Dev Container-only demand without mutating the application Profile? | Complete; pinned rc-demos composition proof passed |
| 004 | [004-support-semantics](004-support-semantics/) | What does current rc-pade do for supported/unsupported required and optional demand? | Complete with finding; optional unsupported demand currently fails closed |

Experiments should preserve the architecture boundaries rather than optimizing for a positive result. Failures that expose environment-specific assumptions are useful evidence.
