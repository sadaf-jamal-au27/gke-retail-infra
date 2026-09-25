# GitHub setup (WIF + environments)

See the monorepo copy for full text:  
https://github.com/sadaf-jamal-au27/gke-microservices/blob/main/.github/GITHUB_SETUP.md

Quick steps:

1. `./scripts/tf.sh dev github_wif apply`
2. `export TF_VAR_DATABASE_PASSWORD='...' && ./scripts/github-set-wif-secrets.sh dev` (requires `gh auth login`)
3. Create **`develop`** branch and protect **`main`** + **`develop`** — see `docs/BRANCHING.md` in monorepo.

Branching strategy: **`docs/BRANCHING.md`** (monorepo path `docs/BRANCHING.md`).
