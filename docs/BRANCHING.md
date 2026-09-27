# Branching: feature → develop → main (PR-only automation)

**Guide:** [`docs/PLATFORM_GUIDE.md`](PLATFORM_GUIDE.md)

Org: **`sadaf-jamal-au27`**. Same flow on every repo.

## Branches

| Branch | Role |
|--------|------|
| **`develop`** | Integration. Feature PRs merge here first. |
| **`main`** | Release gate. Only **`develop` → `main`** PRs. |
| **`feature/<name>`** | Short-lived. Open **PR → `develop`** only (no direct push to develop/main for infra). |

```text
feature/* ──PR──► develop ──PR──► main
              │              │
              │              └─ merge → manual infra-apply (branch main, env prod)
              └─ merge → manual infra-apply (branch develop, env dev)

Every PR → infra-plan (static + GCP plan)
```

## CI — PR + manual apply

| Step | How | Workflow |
|------|-----|----------|
| **Plan** | Open/update **Pull Request** → `develop` or `main` | **infra-plan** |
| **Merge** | Approve PR on GitHub | (no auto apply) |
| **Apply** | **Actions → infra-apply → Run workflow** | **infra-apply** |

| PR target | Plan uses GitHub env | After merge, manual apply |
|-----------|----------------------|---------------------------|
| **`develop`** | `dev` | branch **`develop`**, environment **`dev`**, `tf_env` **`dev`** |
| **`main`** | `prod` | branch **`main`**, environment **`prod`**, `tf_env` **`dev`**\* |

\*Until real prod GCP exists, **`prod` secrets mirror `dev`**.

**No** push-triggered plan or apply — sirf **PR** se plan, **manual dispatch** se apply.

Optional: GitHub → Environments **`dev`** / **`prod`** → **Required reviewers** (human approve before apply job runs).

## Daily workflow

```bash
git checkout develop && git pull
git checkout -b feature/my-change
# edit infra/ or fast/
git push -u origin feature/my-change
# GitHub: Open PR → develop → wait for infra-plan checks → merge

# Then: Actions → infra-apply → branch develop, env dev, tf_env dev → Run

# Release: PR develop → main → merge → infra-apply → branch main, env prod
```

Setup:

```bash
cd ~/Projects/gke-retail-infra
./scripts/git-sync-develop.sh
./scripts/github-setup-branch-protection.sh
```

WIF: **`docs/WIF_AND_GITHUB.md`**.

## Protected branches (no direct push)

**`develop`** and **`main`** must stay protected on GitHub:

- **No direct `git push`** to `develop` or `main` — changes only via **Pull Request**
- **Admins included** (`enforce_admins`) — same rule for everyone
- Required checks on PR: `Terraform static checks`, `Terraform plan (GCP)`
- **`main`**: at least **1 PR approval** before merge
- **`develop`**: PR required (0 approvals by default in script — change in script if you want 1)

Apply protection (both infra repos):

```bash
cd ~/Projects/gke-retail-infra
./scripts/github-setup-branch-protection.sh
# or: ./scripts/github-setup-branch-protection.sh gke-retail-infra gke-microservices
```

Correct flow only:

```text
feature/*  ──PR──►  develop  ──PR──►  main
           (never push directly to develop or main)
```
