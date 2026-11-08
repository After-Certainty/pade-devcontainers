# Public signed handoff fixtures

Public-only producer bundle reused from the rc-demos validated-profile-handoff
experiment (same trust shape as rc-pade Experiments 014–015).

Contains:

- `profile.yaml` — exact Profile bytes under signature
- `evidence.json` / `evidence.sig` — Ed25519 detached signature over evidence
- `extensions/<sha256>.yaml` — resolved extension artifacts
- `trusted.pub` — operator-owned public verification key

Private signing material must never appear here.
