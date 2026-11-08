# Provenance

Repository-local evidence that Experiments 001–010 were executed from a
specific host environment.

This is not a new schema or standard. Prefer concise YAML manifests over raw
logs. Never commit tokens, JWTs, private keys, provider Material, or private
broker endpoints.

## Layout

```text
experiments/provenance/
  README.md
  coder-<UTC-date>/
    environment.md
    001.yaml … 010.yaml
```

## Evidence kinds

1. **Canonical experiment status** — each experiment README (`Complete` /
   `In progress` / finding).
2. **GitHub CI evidence** — deterministic workflows on `ubuntu-latest`.
3. **Coder-hosted provenance** — additional execution from the GCE-backed
   Coder outer host, without changing experiment meaning.

Coder is the outer host used to run standard Dev Containers. Coder-specific
lifecycle machinery is not part of the Dev Container integration contract.
