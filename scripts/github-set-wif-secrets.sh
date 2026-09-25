#!/usr/bin/env bash
# Set GitHub Environment secrets for GCP WIF after: ./scripts/tf.sh dev github_wif apply
set -euo pipefail

ENV="${1:-dev}"
ORG="${GITHUB_OWNER:-sadaf-jamal-au27}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if ! command -v gh >/dev/null; then
  echo "Install GitHub CLI: https://cli.github.com/"
  exit 1
fi

WIF_PROVIDER="$(./scripts/tf.sh "${ENV}" github_wif output -raw workload_identity_provider 2>/dev/null || true)"
CI_SA="$(./scripts/tf.sh "${ENV}" github_wif output -raw ci_service_account_email 2>/dev/null || true)"

if [[ -z "${WIF_PROVIDER}" || -z "${CI_SA}" ]]; then
  echo "Apply github_wif first: ./scripts/tf.sh ${ENV} github_wif apply"
  exit 1
fi

PROJECT_ID="$(grep '^project_id' "fast/datasets/${ENV}/env.tfvars" | head -1 | cut -d'"' -f2)"
REGION="$(grep '^region' "fast/datasets/${ENV}/env.tfvars" | head -1 | cut -d'"' -f2)"

REPOS=(gke-retail-infra gke-retail-application gke-retail-devops gke-microservices)

set_secret() {
  local repo="$1"
  local env_name="$2"
  echo "→ ${ORG}/${repo} environment ${env_name}"
  gh secret set GCP_WIF_PROVIDER --env "${env_name}" --repo "${ORG}/${repo}" --body "${WIF_PROVIDER}"
  gh secret set GCP_CI_SERVICE_ACCOUNT --env "${env_name}" --repo "${ORG}/${repo}" --body "${CI_SA}"
  gh secret set GCP_PROJECT_ID --env "${env_name}" --repo "${ORG}/${repo}" --body "${PROJECT_ID}"
  gh secret set GCP_REGION --env "${env_name}" --repo "${ORG}/${repo}" --body "${REGION}"
  if [[ -n "${TF_VAR_DATABASE_PASSWORD:-}" ]]; then
    gh secret set TF_VAR_DATABASE_PASSWORD --env "${env_name}" --repo "${ORG}/${repo}" --body "${TF_VAR_DATABASE_PASSWORD}"
  else
    echo "  (skip TF_VAR_DATABASE_PASSWORD — export to set on infra repo)"
    if [[ "${repo}" == "gke-retail-infra" ]]; then
      echo "  Infra apply needs TF_VAR_DATABASE_PASSWORD on environment ${env_name}."
    fi
  fi
}

for repo in "${REPOS[@]}"; do
  gh api --method PUT "repos/${ORG}/${repo}/environments/${ENV}" >/dev/null 2>&1 || true
  set_secret "${repo}" "${ENV}"
done

echo "Done."
