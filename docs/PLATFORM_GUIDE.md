# Retail platform on GKE — design, architecture & setup guide

Yeh document **ek jagah** par poori picture deta hai: kya ban raha hai, kaise repos judte hain, GCP par kya deploy hota hai, Git branching kaise chalti hai, aur GitHub Actions **bina JSON key** ke GCP se kaise connect hota hai.

**Org:** `sadaf-jamal-au27`  
**Dev GCP project (abhi):** `ai-rag-agent-project`  
**Region:** `asia-south1` (Mumbai)

Canonical infra repo: **[gke-retail-infra](https://github.com/sadaf-jamal-au27/gke-retail-infra)**  
Is monorepo (`gke-microservices`) mein sirf **infra mirror** hai — naya kaam wahan karo; yahan paths `infra/` ke neeche same cheezein hain.

**Paths:** `gke-retail-infra` repo root par `fast/` aur `scripts/` use karo. Is monorepo mein wahi cheezein `infra/fast/` aur `infra/scripts/` ke andar hain.

---

## 1. Yeh platform kya hai?

Goal: **retail / automobile demo** ke liye microservices GKE par chalana, pehle **foundation** (network, cluster, database, messaging, CI), baad mein **apps + Helm**.

Abhi phase:

| Phase | Status | Kya hota hai |
|-------|--------|----------------|
| **Infra (Terraform FAST)** | Dev par apply ho chuka (local / CI) | VPC, GKE, Cloud SQL, Pub/Sub, GitHub WIF |
| **Application** | Alag repo, baad mein | Docker images, microservices |
| **DevOps / Helm** | Alag repo, baad mein | Pods, Gateway, env values |
| **Cloud Run (BFF)** | Optional stack | Tab jab application image ready ho |

Terraform **pods deploy nahi karta** — sirf GCP foundation. Apps Helm se cluster par aate hain.

---

## 2. Architecture — high level

```mermaid
flowchart TB
  subgraph GitHub["GitHub (sadaf-jamal-au27)"]
    FEAT[feature/* branches]
    DEV[develop]
    MAIN[main]
    GHA[GitHub Actions infra-ci]
    FEAT -->|PR + plan| DEV
    DEV -->|merge + apply| DEV
    DEV -->|PR + plan| MAIN
    MAIN -->|merge + apply| MAIN
    GHA --> DEV
    GHA --> MAIN
  end

  subgraph WIF["GCP — Workload Identity Federation"]
    POOL[WIF pool + provider]
    SA[github-ci-dev@...]
    POOL --> SA
  end

  subgraph GCP["GCP project ai-rag-agent-project"]
    VPC[VPC + subnets]
    GKE[GKE cluster retail-dev]
    SQL[(Cloud SQL retail-dev-pg)]
    PS[Pub/Sub topics]
    AR[Artifact Registry — later]
    CR[Cloud Run BFF — later]
    VPC --> GKE
    VPC --> SQL
    GKE --> AR
    CR --> AR
  end

  GHA -->|OIDC token, no JSON key| POOL
  SA -->|terraform plan/apply| GCP
  GKE -.->|Helm later| APPS[Microservices]
  APPS --> SQL
  APPS --> PS
```

**Flow samajhne ke liye (simple words):**

1. Developer **feature branch** par code change karta hai → PR **`develop`** par → CI **plan** chalata hai (dev secrets).
2. Merge **`develop`** → CI **apply** chalata hai → dev GCP update hota hai.
3. Release ke liye PR **`develop` → `main`** → plan **prod** environment secrets se → merge **`main`** → apply (aaj ke liye same GCP, alag GitHub gate).

---

## 3. Char repos — kaun kya karta hai

| Repo | Role | CI / deploy abhi |
|------|------|------------------|
| **gke-retail-infra** | Terraform FAST, scripts, `infra-ci.yml` | Plan on PR, apply on `develop` / `main` |
| **gke-retail-application** | Node services, BFF, storefront (future) | Build/push images (baad mein) |
| **gke-retail-devops** | Helm charts, deploy scripts (future) | Helm to GKE (baad mein) |
| **gke-microservices** | Purana monorepo — **sirf infra mirror** | Same idea on `infra/**` if you keep it |

**Order of rollout:** infra green → application images → Helm → optional Cloud Run stack.

Detail: `docs/MULTI_REPO.md`.

---

## 4. GCP design — Terraform stacks

Code: `infra/fast/` (Fabric FAST style). Har stack ka **alag state** bucket prefix par.

**Default apply order** (`tf-apply-all.sh`):

```text
project_services → cloud_storage → github_wif → network → gke → cloudsql → pubsub
```

| Stack | Human meaning |
|-------|----------------|
| `project_services` | Zaroori GCP APIs on |
| `cloud_storage` | Buckets (artifacts, backups, state support) |
| `github_wif` | GitHub Actions ke liye WIF + CI service account |
| `network` | VPC, subnets, Private Service Access (SQL ke liye) |
| `gke` | Cluster **`retail-dev`**, workload identity |
| `cloudsql` | PostgreSQL **`retail-dev-pg`** |
| `pubsub` | Event topics |
| `cloudrun` | **Alag se** — BFF image ke baad; default pipeline mein nahi |

**State bucket (dev):** `gs://ai-rag-agent-project-retail-tfstate-dev`

Config files:

- Shared project/region: `infra/fast/datasets/dev/env.tfvars`
- GitHub trust list: `infra/fast/datasets/dev/github_wif.tfvars`

---

## 5. Security — Workload Identity Federation (WIF)

**Problem:** GCP service account JSON key GitHub par rakhna unsafe hai.

**Solution:** GitHub Actions **OIDC token** bhejta hai → GCP **WIF provider** verify karta hai → short-lived access **CI service account** par.

**Kaun se repos trust hain** (`github_wif.tfvars`):

- `gke-retail-infra`, `gke-retail-application`, `gke-retail-devops`, `gke-microservices`

**GitHub par do “Environments”** (secrets alag gate):

| GitHub Environment | Kaun si branch deploy kar sakti hai | GCP aaj |
|--------------------|-------------------------------------|---------|
| **`dev`** | Sirf **`develop`** | `ai-rag-agent-project`, `TF_ENV=dev` |
| **`prod`** | Sirf **`main`** | Abhi **same project** (secrets mirror); baad mein alag prod project |

**Secrets (har infra repo, dono environments par — prod mirror tab tak):**

| Secret | Matlab |
|--------|--------|
| `GCP_WIF_PROVIDER` | WIF provider resource name |
| `GCP_CI_SERVICE_ACCOUNT` | e.g. `github-ci-dev@ai-rag-agent-project.iam.gserviceaccount.com` |
| `GCP_PROJECT_ID` | `ai-rag-agent-project` |
| `GCP_REGION` | `asia-south1` |
| `TF_VAR_DATABASE_PASSWORD` | Cloud SQL password (CI apply ke liye) |

Scripts: `infra/scripts/github-set-wif-secrets.sh`, `github-setup-environments.sh`, `github-setup-branch-protection.sh`.

Short reference: `docs/WIF_AND_GITHUB.md`.

---

## 6. Git branching design

**Best practice is repo mein:** **`feature/*` → `develop` → `main`**

```text
feature/my-change ──PR──► develop ──PR──► main
        │                      │                 │
        │                      │                 └─ push main → terraform apply (GitHub env prod)
        │                      └─ push develop → terraform apply (GitHub env dev)
        └─ PR → terraform plan (GitHub env dev)
```

| Branch | Kaam |
|--------|------|
| `feature/<short-name>` | Naya kaam; PR hamesha pehle **`develop`** par |
| `develop` | Integration; dev GCP yahan apply hota hai |
| `main` | Release line; prod gate (aaj mirror GCP, kal alag prod project) |

**Branch protection (`gke-retail-infra`):** PR required; checks `terraform unit (fast)` + `terraform integration (fast)`.

**Hotfix (kabhi zarurat ho):** `hotfix/*` from `main` → PR `main` → phir `main` ko wapas `develop` mein merge.

Detail: `docs/BRANCHING.md`.

---

## 7. CI pipeline — `infra-ci.yml` (enterprise-style)

Typical company pattern: **static checks without secrets → remote-state plan on PR → plan-then-apply on merge** (no duplicate fake “integration” job).

| Job | Name (required check) | Credentials | What it does |
|-----|----------------------|-------------|--------------|
| **static** | `Terraform static checks` | None | `fmt -check`, `validate` every stack, `terraform test` (unit + module mocks) |
| **terraform-plan** | `Terraform plan (GCP)` | WIF | `terraform init` (GCS backend) + **plan all stacks**, save `.tfplan` artifacts |
| **terraform-apply** | `Terraform apply (GCP)` | WIF + env gate | Same job: **plan to files → apply those plans** (not blind apply) |

Trigger: changes under `infra/**` (monorepo) or `fast/**`, `scripts/**`, `tests/**` (gke-retail-infra).

| Event | Jobs | GitHub Environment | Terraform |
|-------|------|-------------------|-----------|
| PR → `develop` / `main` | static + **plan** | `dev` or `prod` (by base branch) | remote plan |
| Push **develop** / **main** | static + **apply** | matching env | plan → apply |
| Manual dispatch | plan or apply | you choose | you choose |

Scripts:

- Local static: `./infra/scripts/test-static.sh dev`
- Local plan all: `./infra/scripts/tf-plan-all.sh dev` (needs GCP login)
- CI plan: `./infra/scripts/ci-gcp-plan.sh dev`
- CI deploy: `./infra/scripts/ci-gcp-apply.sh dev`

Branch protection should require **`Terraform static checks`** and **`Terraform plan (GCP)`** on PRs:

```bash
./scripts/github-setup-branch-protection.sh
```

---

## 8. Pehli baar setup — step by step

Yeh steps **ek baar** (ya naye machine par) follow karo. Canonical path: `~/Projects/gke-retail-infra` (ya yahan `cd infra`).

### Step A — Tools aur login

1. Install: `gcloud`, `terraform` (≥ 1.10.2 for CI parity), `gh` CLI.
2. `gcloud auth login` aur project set:  
   `gcloud config set project ai-rag-agent-project`
3. GitHub: `gh auth login` aur agar push fail ho: `gh auth setup-git`

### Step B — Bootstrap remote state

```bash
cd ~/Projects/gke-retail-infra   # or: cd infra inside gke-microservices
./scripts/gcp-bootstrap.sh dev
```

Isse state bucket aur base APIs ready hoti hain.

### Step C — Password (Cloud SQL ke liye)

Password git mein **kabhi mat** daalo. Terminal mein export:

```bash
export TF_VAR_database_password='apna-strong-password'
```

CI ke liye wahi value baad mein GitHub secret `TF_VAR_DATABASE_PASSWORD` mein jati hai.

### Step D — Terraform apply (local ya baad mein CI)

```bash
./scripts/tf-apply-all.sh dev plan
./scripts/tf-apply-all.sh dev apply
```

`gke` + `cloudsql` mein 15–30+ minute lag sakte hain; plan pehle dhyaan se padho.

### Step E — GitHub WIF secrets + environments

`github_wif` stack apply ke baad:

```bash
export TF_VAR_DATABASE_PASSWORD='same-as-above'
./scripts/github-set-wif-secrets.sh dev --mirror-prod
./scripts/github-setup-environments.sh
./scripts/github-setup-branch-protection.sh
```

Verify:

```bash
gh secret list --env dev --repo sadaf-jamal-au27/gke-retail-infra
gh secret list --env prod --repo sadaf-jamal-au27/gke-retail-infra
```

### Step F — `develop` branch

Agar remote par nahi hai:

```bash
git checkout main && git pull
git checkout -b develop && git push -u origin develop
```

(Optional) GitHub → Environment **`prod`** → **Required reviewers** add karo taaki `main` apply approve ke baad chale.

---

## 9. Roz ka kaam — developer workflow

```bash
git checkout develop && git pull origin develop
git checkout -b feature/short-description

# edit infra/fast/ or scripts/
git add … && git commit -m "…"
git push -u origin feature/short-description
```

1. GitHub par **Pull request → base `develop`** kholo.
2. Wait: unit, integration, **GCP terraform plan** (green).
3. Merge → automatically **apply** on **`develop`** (dev environment).
4. Release: **PR `develop` → `main`** → plan (prod env) → merge → apply on **`main`**.

Feature branch ko **seedha `main` par mat** bhejo (sirf hotfix exception).

---

## 10. Agla phase — apps, Helm, Cloud Run

Jab infra stable ho:

1. **gke-retail-application** clone → build/push images to Artifact Registry.
2. **gke-retail-devops** → `helm upgrade` against `retail-dev` (Gateway API cluster par enable karna pad sakta hai).
3. **Cloud Run:**  
   `./scripts/tf.sh dev cloudrun plan` / `apply` — tab jab BFF image registry mein ho.

Purani monorepo mein `application/` / `devops/` hata diya gaya; woh content future mein alag repos se aayega.

Local infra detail: `docs/INFRA_SETUP.md` (kuch CI bullets purane ho sakte hain — branching ke liye **is guide + BRANCHING.md** source of truth).

---

## 11. Verify — sab theek hai?

**Terraform outputs:**

```bash
./scripts/tf.sh dev gke output
./scripts/tf.sh dev cloudsql output
./scripts/tf.sh dev github_wif output
```

**Cluster (kubectl):**

```bash
gcloud container clusters get-credentials retail-dev \
  --region asia-south1 --project ai-rag-agent-project
kubectl get nodes
```

**CI:** PR feature→develop par plan job; merge develop par apply job — Actions tab par dekho.

---

## 12. Common problems

| Symptom | Likely fix |
|---------|------------|
| `git push` username/password error | `gh auth setup-git` |
| No local `develop` | `git fetch && git checkout -b develop origin/develop` |
| Plan/apply 403 on GCP | Billing + IAM on project; WIF stack applied |
| Cloud SQL password error | `export TF_VAR_database_password=…` |
| Apply fails on `cloudrun` | Stack ko default apply se hata diya — pehle image build karo |
| Prod apply same as dev | Expected until real prod project + `fast/datasets/prod/` |

---

## 13. Document map

| File | Use when |
|------|----------|
| **This file (`PLATFORM_GUIDE.md`)** | Poori design + end-to-end steps |
| `docs/BRANCHING.md` | Sirf Git flow table |
| `docs/WIF_AND_GITHUB.md` | WIF commands cheat sheet |
| `docs/INFRA_SETUP.md` | Terraform phases, stack detail |
| `docs/MULTI_REPO.md` | Repo URLs aur rollout order |
| `.github/GITHUB_SETUP.md` | One-screen GitHub pointer |

---

## 14. Checklist (dev ready)

- [ ] GCP project `ai-rag-agent-project`, billing on, `asia-south1`
- [ ] `gcp-bootstrap.sh dev` run
- [ ] `github_wif.tfvars` mein sahi org + repo list
- [ ] `tf-apply-all.sh dev apply` success (through `pubsub`)
- [ ] GitHub env `dev` + `prod` secrets + branch policies
- [ ] Remote branches `develop` + `main`, protection on infra repo
- [ ] Ek test PR feature→develop → plan green
- [ ] (Later) prod GCP project + non-mirror prod secrets
- [ ] (Later) application images + Helm + optional `cloudrun`

---

*Last updated for branching `feature → develop → main`, WIF on four repos, and default apply without `cloudrun`.*
