# Terraform GCS backend config (generated)

One `.hcl` per stack per environment. Used by `tf.sh`:

```bash
terraform init -backend-config=../../backends/dev/gke.hcl
```

| Path | Meaning |
|------|---------|
| `backends/<env>/<stack>.hcl` | `bucket` + `prefix` for that stack's state |

**Source of truth for bucket name:** `datasets/<env>/env.tfvars` → `state_bucket`.

After changing `state_bucket`, run `node infra/scripts/generate-fast-stages.mjs`.

Stage roots only declare `backend "gcs" {}` in `backend.tf` — settings live here.
