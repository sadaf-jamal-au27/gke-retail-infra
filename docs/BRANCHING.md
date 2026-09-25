# Branching: feature → develop → main

Org: **`sadaf-jamal-au27`**. Same flow on every repo.

## Branches

| Branch | Role |
|--------|------|
| **`develop`** | Integration. Feature PRs merge here first. Terraform **apply** targets GitHub Environment **`dev`**. |
| **`main`** | Release / production gate. Only **`develop` → `main`** PRs. Apply uses GitHub Environment **`prod`**. |
| **`feature/<name>`** | Short-lived. **Never** PR directly to `main` (except hotfix — see below). |

```text
feature/add-vpc ──PR──► develop ──PR──► main
         │                  │              │
         │                  │              └─ push main → apply (env prod)
         │                  └─ push develop → apply (env dev)
         └─ PR → plan (env dev)
```

## Infra CI (`gke-retail-infra`)

| Event | GitHub Environment | Terraform `TF_ENV` | Action |
|-------|-------------------|-------------------|--------|
| PR → **`develop`** | `dev` | `dev` | plan |
| PR → **`main`** (from develop) | `prod` | `dev`* | plan |
| Push **`develop`** | `dev` | `dev` | apply |
| Push **`main`** | `prod` | `dev`* | apply |
| Run workflow | you choose | you choose | plan / apply |

\*Until a real prod GCP project exists, **`prod` GitHub secrets mirror `dev`** and `TF_ENV` stays **`dev`**. When prod project is ready, set `fast/datasets/prod/env.tfvars` and use `tf_env: prod` on dispatch.

## Hotfix (optional)

`hotfix/*` from **`main`** → PR **`main`**, then merge **`main`** back into **`develop`**.

## Branch protection

| Branch | Rule |
|--------|------|
| **`develop`** | Require PR; checks: `terraform unit (fast)`, `terraform integration (fast)` |
| **`main`** | Require PR; **only merge from `develop`** (no direct feature commits); same checks + optional reviewer on **`prod`** environment |

Setup:

```bash
cd ~/Projects/gke-retail-infra
./scripts/github-setup-branch-protection.sh
```

## Daily workflow

```bash
git checkout develop && git pull
git checkout -b feature/my-infra-change
# edit fast/ or scripts/
git push -u origin feature/my-infra-change
# Open PR → develop → wait for plan → merge → apply on develop

# Release
# Open PR develop → main → plan (prod env) → merge → apply on main
```

## Other repos

| Repo | Flow |
|------|------|
| gke-retail-application | feature → develop → main (build CI only for now) |
| gke-retail-devops | same |
| gke-microservices | infra mirror; same CI idea on `infra/**` |

WIF: **`docs/WIF_AND_GITHUB.md`**.
