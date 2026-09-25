#!/usr/bin/env bash
# Set GitHub Environment secrets for GCP WIF after: ./scripts/tf.sh dev github_wif apply
#
# Usage:
#   export TF_VAR_DATABASE_PASSWORD='...'
#   ./scripts/github-set-wif-secrets.sh dev
#   ./scripts/github-set-wif-secrets.sh dev --mirror-prod   # copy same WIF to GitHub env "prod"
set -euo pipefail

TF_DATASET="${1:-dev}"
MIRROR_PROD=false
[[ "${2:-}" == "--mirror-prod" || "${1:-}" == "--mirror-prod" ]] && MIRROR_PROD=true

ORG="${GITHUB_OWNER:-sadaf-jamal-au27}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if ! command -v gh >/dev/null; then
  echo "Install GitHub CLI: https://cli.github.com/"
  exit 1
fi

if [[ ! -f "fast/datasets/${TF_DATASET}/env.tfvars" ]]; then
  echo "Run from gke-retail-infra root (or monorepo infra/). Missing fast/datasets/${TF_DATASET}/env.tfvars"
  exit 1
fi

WIF_PROVIDER="$(./scripts/tf.sh "${TF_DATASET}" github_wif output -raw workload_identity_provider)"
CI_SA="$(./scripts/tf.sh "${TF_DATASET}" github_wif output -raw ci_service_account_email)"

PROJECT_ID="$(grep '^project_id' "fast/datasets/${TF_DATASET}/env.tfvars" | head -1 | cut -d'"' -f2)"
REGION="$(grep '^region' "fast/datasets/${TF_DATASET}/env.tfvars" | head -1 | cut -d'"' -f2)"

ALL_REPOS=(gke-retail-infra gke-retail-application gke-retail-devops gke-microservices)
INFRA_REPOS=(gke-retail-infra gke-microservices)

apply_secrets() {
  local gh_env="$1"
  for repo in "${ALL_REPOS[@]}"; do
    echo "→ ${ORG}/${repo} GitHub environment '${gh_env}'"
    gh api --method PUT "repos/${ORG}/${repo}/environments/${gh_env}" >/dev/null 2>&1 || true
    gh secret set GCP_WIF_PROVIDER --env "${gh_env}" --repo "${ORG}/${repo}" --body "${WIF_PROVIDER}"
    gh secret set GCP_CI_SERVICE_ACCOUNT --env "${gh_env}" --repo "${ORG}/${repo}" --body "${CI_SA}"
    gh secret set GCP_PROJECT_ID --env "${gh_env}" --repo "${ORG}/${repo}" --body "${PROJECT_ID}"
    gh secret set GCP_REGION --env "${gh_env}" --repo "${ORG}/${repo}" --body "${REGION}"
  done

  if [[ -n "${TF_VAR_DATABASE_PASSWORD:-}" ]]; then
    for repo in "${INFRA_REPOS[@]}"; do
      gh secret set TF_VAR_DATABASE_PASSWORD --env "${gh_env}" --repo "${ORG}/${repo}" --body "${TF_VAR_DATABASE_PASSWORD}"
    done
  fi
}

apply_secrets "dev"

if [[ "${MIRROR_PROD}" == true ]]; then
  echo ""
  echo "Mirroring secrets to GitHub environment 'prod' (same GCP until prod project exists) …"
  apply_secrets "prod"
elif [[ -z "${TF_VAR_DATABASE_PASSWORD:-}" ]]; then
  echo "Tip: export TF_VAR_DATABASE_PASSWORD='...'"
fi

echo ""
echo "Next: ./scripts/github-setup-environments.sh"
echo "Docs: docs/WIF_AND_GITHUB.md"
