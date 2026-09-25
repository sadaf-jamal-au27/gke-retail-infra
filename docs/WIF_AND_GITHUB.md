# WIF + GitHub Actions setup

**GCP dev project:** `ai-rag-agent-project` · **region:** `asia-south1`  
**Branching:** feature → **`develop`** → **`main`** (see `docs/BRANCHING.md`)

## 1. GCP: Workload Identity Federation

`fast/datasets/dev/github_wif.tfvars` trusts:

- `gke-retail-infra`, `gke-retail-application`, `gke-retail-devops`, `gke-microservices`

```bash
./scripts/tf.sh dev github_wif apply
./scripts/tf.sh dev github_wif output
```

## 2. GitHub: two Environments

| GitHub Environment | Branch allowed to deploy | GCP today |
|--------------------|--------------------------|-----------|
| **`dev`** | **`develop`** | `ai-rag-agent-project` (`TF_ENV=dev`) |
| **`prod`** | **`main`** | same project until prod GCP exists* |

\*When prod project exists, add `fast/datasets/prod/`, apply infra there, and set **`prod`** secrets from that stack.

### One-time setup (requires `gh auth login`)

```bash
cd ~/Projects/gke-retail-infra
export TF_VAR_DATABASE_PASSWORD='cloudsql-password'
./scripts/github-set-wif-secrets.sh dev --mirror-prod
./scripts/github-setup-environments.sh
./scripts/github-setup-branch-protection.sh
```

Creates secrets:

| Secret | Purpose |
|--------|---------|
| `GCP_WIF_PROVIDER` | WIF provider resource name |
| `GCP_CI_SERVICE_ACCOUNT` | `github-ci-dev@...` |
| `GCP_PROJECT_ID` | GCP project |
| `GCP_REGION` | `asia-south1` |
| `TF_VAR_DATABASE_PASSWORD` | infra repos only |

On both **`dev`** and **`prod`** GitHub environments (mirror until real prod).

## 3. Ensure `develop` exists

```bash
gh api repos/sadaf-jamal-au27/gke-retail-infra/git/refs -f ref='refs/heads/develop' -f sha="$(gh api repos/sadaf-jamal-au27/gke-retail-infra/git/ref/heads/main --jq .object.sha)"
```

Or: `git checkout -b develop && git push -u origin develop`

## 4. Verify

```bash
gh secret list --env dev --repo sadaf-jamal-au27/gke-retail-infra
gh secret list --env prod --repo sadaf-jamal-au27/gke-retail-infra
```

- PR **feature → develop** → job **GCP terraform plan** (environment **dev**)
- Merge **develop** → push → **GCP terraform apply** (environment **dev**)
- PR **develop → main** → plan (environment **prod**)
- Merge **main** → apply (environment **prod**)

## 5. Prod GCP later

1. Fill `fast/datasets/prod/env.tfvars`  
2. `./scripts/gcp-bootstrap.sh prod` && `./scripts/tf-apply-all.sh prod apply`  
3. `./scripts/github-set-wif-secrets.sh prod` (no mirror)  
4. GitHub **prod** environment → add required reviewers
