# Branching: feature → develop → main

**Poori design + architecture + setup:** [`docs/PLATFORM_GUIDE.md`](PLATFORM_GUIDE.md)

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

## Infra CI — two workflows

| Workflow | File | When it runs |
|----------|------|----------------|
| **Plan** | `.github/workflows/infra-plan.yml` | PR → `develop` / `main`; push to **`feature/**`**; manual |
| **Apply** | `.github/workflows/infra-apply.yml` | Push to **`develop`** / **`main`** only (after merge); manual |

| Event | Workflow | GitHub Environment | Terraform |
|-------|----------|-------------------|-----------|
| PR → **`develop`** | infra-plan | `dev` | plan |
| PR → **`main`** | infra-plan | `prod` | plan |
| Push **`feature/*`** | infra-plan | `dev` | plan (early feedback) |
| Push **`develop`** | infra-apply | `dev` | apply |
| Push **`main`** | infra-apply | `prod` | apply |

\*Until a real prod GCP project exists, **`prod` GitHub secrets mirror `dev`** and `TF_ENV` stays **`dev`**. When prod project is ready, set `fast/datasets/prod/env.tfvars` and use `tf_env: prod` on dispatch.

## Hotfix (optional)

`hotfix/*` from **`main`** → PR **`main`**, then merge **`main`** back into **`develop`**.

## Branch protection

| Branch | Rule |
|--------|------|
| **`develop`** | Require PR; checks: `Terraform static checks`, `Terraform plan (GCP)` |
| **`main`** | Same checks + optional reviewer on **`prod`** environment |

Setup remote **`develop`** (once):

```bash
cd ~/Projects/gke-retail-infra
./scripts/git-sync-develop.sh
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
