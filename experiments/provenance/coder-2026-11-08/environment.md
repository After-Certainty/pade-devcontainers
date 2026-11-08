# Coder execution environment — 2026-11-08

Non-secret context for the Coder-hosted run of Experiments 001–010.

| Field | Value |
|-------|-------|
| Outer host | GCE-backed Coder workspace (Coder is host only; not part of the Dev Container contract) |
| OS | Debian GNU/Linux 12 (bookworm) |
| Architecture | x86_64 |
| Date/time (UTC) | 2026-11-08 (runs spanning ~03:49–04:14Z) |
| Docker | 20.10.24+dfsg1 |
| Podman | 4.3.1 (installed; rootless build failed on host cgroup/systemd linger) |
| Dev Containers CLI | 0.90.0 |
| Go | go1.26.10 linux/amd64 |
| Node | v22.21.0 |
| PADE | v0.4.1 (`05fb036`) |
| rc-pade | `43226ef96ae09419b6253a6eb364fd44a0ac1305` |
| rc-demos | `853eab3c2c04f9d1059b2dbd64ea91996828a3a9` |
| go-rc-profiler (verifier dep) | `5d2e860e48842b89ec83414123a7e59228f61d36` |
| GCE workload identity from host | reachable |
| GCE workload identity from inside Dev Container | reachable on default bridge network (no host-network workaround required) |

`pade-devcontainers` commit under test is recorded per-experiment as
`commitUnderTest` (branch `test/coder-provenance-experiments-001-010` head
containing the live harness).

Not recorded: Coder workspace ID, GCP project identifiers, broker URL, tokens,
numeric Google subjects, provider Material.
