# FAST / Fabric landing zone structure

This repo uses an **adapted** [Cloud Foundation Fabric FAST](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast) layout for **one GCP project per environment** (not full org multi-project FAST).

Upstream FAST uses many stages (`0-bootstrap`, `1-resman`, `2-networking`, …) and **`*.auto.tfvars.json`** files copied from a central output bucket. We use a **smaller stage model** and **`terraform_remote_state`** between stacks instead — valid for single-project retail, but the **file layout must still be disciplined**.

---

## Directory layout

```text
infra/fast/
  datasets/                      ← YOU EDIT HERE (per environment)
    dev/
      env.tfvars                 project_id, region, env, state_bucket
      project_services.tfvars
      cloud_storage.tfvars
      github_wif.tfvars
      network.tfvars             CIDRs, connector
      gke.tfvars
      cloudsql.tfvars
      pubsub.tfvars
      cloudrun.tfvars
    qa|test|prod/                same pattern (placeholders until projects exist)
  backends/                      ← GENERATED: GCS backend *.hcl (one per stack per env)
    dev/
      gke.hcl                    bucket + prefix
      network.hcl
      …
  modules/                       Reusable Terraform wrappers
    _scaffold/                   backend.tf, provider.tf, versions.tf (copied to stages)
    network/                     Fabric net-vpc + serverless connector
    gke/, cloudsql/, …
  stages/                        GENERATED roots — do not put env values here
    0-bootstrap/
      project_services/
      cloud_storage/
      github_wif/
    1-network/
      network/
    2-platform/
      gke/
      cloudsql/
      pubsub/
      cloudrun/                  optional; not in default tf-apply-all
```

**Rule:** `stages/**` = wiring (modules + remote state + outputs).  
**Rule:** `datasets/<env>/**` = environment-specific **values**.  
**Rule:** `backends/<env>/*.hcl` = remote **state location** (regenerate after `state_bucket` changes).

Legacy `stages/.../<stack>.tfvars` files are **deprecated**; `tf.sh` warns if it must fall back to them.

---

## Stages vs upstream Fabric FAST

| Topic | Upstream FAST | This repo |
|-------|---------------|-----------|
| Scope | Org, folders, many projects | One project per env |
| Cross-stage inputs | GCS `tfvars/*.auto.tfvars.json` | `terraform_remote_state` (GKE, SQL, Cloud Run) |
| State | Per-stage bucket/prefix | `fast/backends/<env>/<stack>.hcl` + `datasets/<env>/env.tfvars` (`state_bucket`) |
| Network module | `modules/net-vpc` | Same (`modules/network` → Fabric `net-vpc` v39) |
| Bootstrap | Stage 0 creates IaC bucket | **`gcp-bootstrap.sh`** creates state bucket; `cloud_storage` stack **reads** it (no duplicate resource) |

Stage numbering aligns with intent, not Fabric’s exact names:

| Folder | Purpose |
|--------|---------|
| `0-bootstrap` | APIs, assets bucket, GitHub WIF |
| `1-network` | VPC, subnets, PSA, VPC connector |
| `2-platform` | GKE, Cloud SQL, Pub/Sub, (Cloud Run) |

---

## Apply order & dependencies

```text
project_services → cloud_storage → github_wif → network → gke → cloudsql → pubsub
                                                          ↘ cloudrun (needs GKE + app image)
```

| Stack | Remote state reads | Notes |
|-------|-------------------|--------|
| `network` | — | Outputs VPC/subnet/connector IDs |
| `gke` | `network` | Private cluster on GKE subnet |
| `cloudsql` | `network` | Private IP via PSA |
| `cloudrun` | `network`, `gke` | BFF SA + connector |

`var.state_bucket` in every stage must match `state_bucket` in `datasets/<env>/env.tfvars` (used by remote state data sources). After changing `state_bucket`, run `node infra/scripts/generate-fast-stages.mjs` to refresh `backends/<env>/*.hcl`.

### Remote state files (GCS)

| Layer | VS Code path | Contents |
|-------|----------------|----------|
| Backend **type** | `stages/<stack>/backend.tf` | `backend "gcs" {}` only |
| Backend **settings** | `backends/dev/gke.hcl` (example) | `bucket`, `prefix` |
| Bucket name source | `datasets/dev/env.tfvars` | `state_bucket = "..."` |
| Init wiring | `infra/scripts/tf.sh` | `terraform init -backend-config=.../backends/<env>/<stack>.hcl` |

**Modules** (`fast/modules/*`) have **no** backend — only **stack roots** under `stages/` do.

---

## Commands

Regenerate stage roots after changing `generate-fast-stages.mjs` or module interfaces:

```bash
node infra/scripts/generate-fast-stages.mjs
```

Plan/apply (loads `datasets/<env>/env.tfvars` + `datasets/<env>/<stack>.tfvars`):

```bash
export TF_VAR_database_password='…'   # cloudsql only
./infra/scripts/tf.sh dev network init
./infra/scripts/tf-plan-all.sh dev
./infra/scripts/tf-apply-all.sh dev apply
```

First-time bucket (before any remote backend):

```bash
./infra/scripts/gcp-bootstrap.sh dev
```

---

## What was wrong before (fixed)

1. **Tfvars in two places** — values under `stages/.../*.tfvars` and `datasets/`; load order was confusing. **Now:** datasets only (canonical).
2. **State bucket twice** — bootstrap + `cloud_storage` resource with same name. **Now:** bootstrap creates; module uses `data.google_storage_bucket`.
3. **`state_bucket`** — init ignored `env.tfvars` and recomputed name. **Now:** read from `env.tfvars`.
4. **Generator** — wrote empty stack tfvars under stages. **Now:** seeds `datasets/<env>/<stack>.tfvars` if missing; marks legacy stage tfvars deprecated.
5. **Variables** — many stacks had no defaults; validate/plan depended on hidden stage tfvars. **Now:** sensible defaults in generated `variables.tf`; datasets override for real envs.

---

## Related docs

- [`PLATFORM_GUIDE.md`](PLATFORM_GUIDE.md) — end-to-end platform
- [`INFRA_SETUP.md`](INFRA_SETUP.md) — bootstrap & apply phases
- [`../fast/README.md`](../infra/fast/README.md) — short reference
