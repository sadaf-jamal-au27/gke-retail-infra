# Module file standard (Fabric FAST landing zone)

Reusable modules: `infra/fast/modules/<name>/`

Live Terraform roots: `infra/fast/stages/<stage>/<stack>/`

| File | Purpose |
|------|---------|
| `backend.tf` | `backend "gcs" {}` only |
| `versions.tf` | Terraform + provider pins |
| `provider.tf` | Google providers |
| `variables.tf` | Inputs |
| `main.tf` | Module call |
| `outputs.tf` | Exported values |

**Network** uses [Cloud Foundation Fabric `net-vpc`](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/net-vpc) (`v39.0.0`).

Regenerate stage roots:

```bash
node infra/scripts/generate-fast-stages.mjs
```
