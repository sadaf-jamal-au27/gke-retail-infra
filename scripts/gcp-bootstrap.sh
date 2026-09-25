#!/usr/bin/env bash
# Bootstrap GCP for one environment: enable core APIs + create Terraform state bucket.
set -euo pipefail

ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_TFVARS="${ROOT}/fast/datasets/${ENV}/env.tfvars"

if [[ ! -f "${ENV_TFVARS}" ]]; then
  echo "Missing ${ENV_TFVARS}. Run: node scripts/generate-fast-stages.mjs"
  exit 1
fi

PROJECT_ID="$(grep '^project_id' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
REGION="$(grep '^region' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
STATE_BUCKET="$(grep '^state_bucket' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
STATE_BUCKET="${STATE_BUCKET:-${PROJECT_ID}-retail-tfstate-${ENV}}"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == REPLACE_* ]]; then
  echo "Edit ${ENV_TFVARS} and set a real project_id before bootstrap."
  exit 1
fi

REGION="${REGION:-asia-south1}"

echo "Bootstrapping project ${PROJECT_ID} (${ENV}) in ${REGION}"

gcloud config set project "${PROJECT_ID}"

APIS=(
  compute.googleapis.com
  container.googleapis.com
  sqladmin.googleapis.com
  servicenetworking.googleapis.com
  pubsub.googleapis.com
  run.googleapis.com
  artifactregistry.googleapis.com
  iam.googleapis.com
  iamcredentials.googleapis.com
  cloudresourcemanager.googleapis.com
  storage.googleapis.com
  secretmanager.googleapis.com
)

for api in "${APIS[@]}"; do
  gcloud services enable "${api}" --project "${PROJECT_ID}"
done

if ! gcloud storage buckets describe "gs://${STATE_BUCKET}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${STATE_BUCKET}" --project="${PROJECT_ID}" --location="${REGION}" --uniform-bucket-level-access
  gcloud storage buckets update "gs://${STATE_BUCKET}" --versioning
  echo "Created state bucket gs://${STATE_BUCKET}"
else
  echo "State bucket already exists: gs://${STATE_BUCKET}"
fi

echo ""
echo "Bootstrap complete. Next:"
echo "  1. Edit fast/datasets/${ENV}/*.tfvars (especially github_wif.tfvars)"
echo "  2. export TF_VAR_database_password='strong-password'"
echo "  3. ./scripts/tf-apply-all.sh ${ENV} plan"
echo "  4. ./scripts/tf-apply-all.sh ${ENV} apply"
echo ""
echo "Guide: docs/FAST_STRUCTURE.md"
