# Environment datasets (single source of truth)

Edit values here — not `stages/**/<stack>.tfvars`.

| File | Purpose |
|------|---------|
| `env.tfvars` | project_id, region, env, state_bucket |
| `<stack>.tfvars` | Stack-specific sizing, CIDRs, GitHub org/repos |
| `service_account.tfvars` | GKE Workload Identity (used by `gke` stack) |

Remote state bucket/prefix: **`fast/backends/<env>/<stack>.hcl`** (generated; keep in sync with `state_bucket` here).

See `docs/FAST_STRUCTURE.md`.
