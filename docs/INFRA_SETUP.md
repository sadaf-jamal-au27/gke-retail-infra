# Infrastructure setup (GCP + Terraform + GKE + Helm)

Pure Terraform **Fabric FAST** landing zone under `infra/fast/`. No Terragrunt.

**Your dev project (configured):** `ai-rag-agent-project` · region `asia-south1`

---

## Phase 0 — CI (GitHub)

On every PR touching `infra/**`:

1. **Unit** — `terraform fmt -check`, `validate` all FAST stacks, `terraform test`
2. **Integration** — repeats unit (fast smoke)
3. **GCP plan** — needs GitHub Environment **dev** secrets (after `github_wif` apply)

Local:

```bash
./infra/scripts/test-unit.sh dev
./infra/scripts/test-integration.sh dev
```

Workflow: `.github/workflows/infra-ci.yml`

---

## Phase 0 — Prerequisites

| Tool | Check |
|------|--------|
| gcloud | `gcloud auth login` and `gcloud config set project ai-rag-agent-project` |
| Terraform | `terraform version` (≥ 1.5) |
| Billing | GCP project must have billing enabled |
| Permissions | Owner or Editor + ability to enable APIs and create GKE/SQL |

Optional later: `kubectl`, `helm`, Docker (for building images to Artifact Registry).

---

## Phase 1 — Bootstrap (once per environment)

Creates the **remote state bucket** and enables the same APIs Terraform will manage:

```bash
./infra/scripts/gcp-bootstrap.sh dev
```

State bucket: `gs://ai-rag-agent-project-retail-tfstate-dev`

---

## Phase 2 — Edit config before apply

### 2.1 `env.tfvars` (per environment)

File: `infra/fast/datasets/dev/env.tfvars`

Set GitHub org/repo for **Workload Identity Federation** (GitHub Actions → GCP):

```hcl
github_org  = "your-github-username-or-org"
github_repo = "gke-microservices"
```

If you skip WIF for now, you can still apply other stacks locally with your user credentials; apply `github_wif` only after these are real values.

### 2.2 Cloud SQL password

Never commit the password. Export before `plan`/`apply` when the `cloudsql` stack runs:

```bash
export TF_VAR_database_password='choose-a-strong-password'
```

### 2.3 Other environments (qa / test / prod)

Replace `REPLACE_GCP_*` project IDs in each env’s `env.tfvars`, run bootstrap per env, then apply.

Regenerate stack folders after module changes:

```bash
node infra/scripts/generate-fast-stages.mjs
```

---

## Phase 3 — Terraform apply order

Stacks and dependencies:

```text
project_services → cloud_storage → github_wif → network → gke → cloudsql → pubsub → cloudrun
```

Each stack has its own state prefix: `gs://…/{env}/{stack}/`.

### Single stack

```bash
./infra/scripts/tf.sh dev project_services init
./infra/scripts/tf.sh dev project_services plan
./infra/scripts/tf.sh dev project_services apply
```

### All stacks

```bash
export TF_VAR_database_password='…'
./infra/scripts/tf-apply-all.sh dev plan
./infra/scripts/tf-apply-all.sh dev apply
```

**Time/cost note:** `gke` and `cloudsql` take ~15–30+ minutes and incur ongoing cost. Review `plan` before `apply`.

### What each stack creates (summary)

| Stack | Purpose |
|-------|---------|
| `project_services` | Enables GCP APIs |
| `cloud_storage` | Buckets for artifacts/backups |
| `github_wif` | WIF pool + CI service account for GitHub Actions |
| `network` | VPC, subnets, PSA for Cloud SQL |
| `gke` | Autopilot/standard cluster `retail-dev`, workload SA |
| `cloudsql` | PostgreSQL `retail-dev-pg` |
| `pubsub` | Topics for async events |
| `cloudrun` | Optional Cloud Run jobs/services |

After `github_wif` apply:

```bash
./infra/scripts/tf.sh dev github_wif output
```

Copy outputs into GitHub Environment **dev** secrets (see `.github/GITHUB_SETUP.md`).

---

## Phase 4 — GitHub Actions (optional)

1. Create GitHub Environments: `dev`, `qa`, `test`, `prod`.
2. Add secrets per environment: `GCP_WIF_PROVIDER`, `GCP_CI_SERVICE_ACCOUNT`, `GCP_PROJECT_ID`, `GCP_REGION`, `TF_VAR_DATABASE_PASSWORD`.
3. Run workflow **terraform-live** (manual dispatch) or open a PR touching `infra/terraform/**` for plan on dev.

---

## Phase 5 — Images + Helm on GKE

Terraform does **not** deploy microservice pods. After GKE exists:

### 5.1 Connect kubectl

```bash
gcloud container clusters get-credentials retail-dev --region asia-south1 --project ai-rag-agent-project
```

### 5.2 Gateway API (once per cluster)

```bash
gcloud container clusters update retail-dev \
  --region=asia-south1 --gateway-api=standard
```

### 5.3 Build & push images (example)

Create Artifact Registry repo if needed, then build/push service images referenced in Helm values (`values-dev.yaml` → `imageRegistry`).

### 5.4 Helm deploy

Automobile demo (10 services + BFF) — use `services.automobile-10.yaml` if you extend the script, or:

```bash
helm upgrade --install retail-dev devops/helm/retail-platform \
  --namespace retail-dev --create-namespace \
  -f devops/helm/retail-platform/values.yaml \
  -f devops/helm/retail-platform/values-dev.yaml \
  -f devops/helm/retail-platform/services.automobile-10.yaml \
  --wait --timeout 20m
```

Full 51-service chart: `services.generated.yaml` (see `docs/runbooks/RUNBOOK-HELM.md`).

Update `values-dev.yaml` hostnames (`dev-shop.example.com`) and DNS when you add a real domain.

---

## Phase 6 — Verify

```bash
# Terraform outputs (example)
./infra/scripts/tf.sh dev gke output
./infra/scripts/tf.sh dev cloudsql output

# Cluster
kubectl get nodes
kubectl -n retail-dev get pods,svc,gateway
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Error 403` enabling APIs | Confirm billing + IAM on project |
| `github_wif` plan asks for org/repo | Set `github_org` / `github_repo` in `env.tfvars` |
| `cloudsql` fails on password | `export TF_VAR_database_password=…` |
| State bucket missing | `./infra/scripts/gcp-bootstrap.sh dev` |
| Helm ImagePullBackOff | Push images to `imageRegistry` in values-dev.yaml |
| Old Terragrunt docs | Use `infra/README.md` and this file only |

---

## Quick checklist (dev)

- [ ] `gcloud` logged in, project `ai-rag-agent-project`
- [ ] `./infra/scripts/gcp-bootstrap.sh dev`
- [ ] `github_org` / `github_repo` in `env.tfvars`
- [ ] `TF_VAR_database_password` exported
- [ ] `./infra/scripts/tf-apply-all.sh dev apply`
- [ ] GitHub secrets from `github_wif` outputs
- [ ] `get-credentials` + Helm deploy
- [ ] DNS / Gateway hostname (when going public)
