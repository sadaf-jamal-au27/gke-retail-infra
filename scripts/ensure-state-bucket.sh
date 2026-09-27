#!/usr/bin/env bash
# Create the GCS Terraform state bucket if missing (required before any terraform init).
set -euo pipefail

ENV="${1:?Usage: ensure-state-bucket.sh <dev|qa|test|prod>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_TFVARS="${ROOT}/fast/datasets/${ENV}/env.tfvars"

if [[ ! -f "${ENV_TFVARS}" ]]; then
  echo "Missing ${ENV_TFVARS}"
  exit 1
fi

PROJECT_ID="$(grep '^project_id' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
REGION="$(grep '^region' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
STATE_BUCKET="$(grep '^state_bucket' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
STATE_BUCKET="${STATE_BUCKET:-${PROJECT_ID}-retail-tfstate-${ENV}}"
REGION="${REGION:-asia-south1}"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == REPLACE_* ]]; then
  echo "Set project_id in ${ENV_TFVARS}"
  exit 1
fi

gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud services enable storage.googleapis.com --project="${PROJECT_ID}" >/dev/null

if gcloud storage buckets describe "gs://${STATE_BUCKET}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "State bucket exists: gs://${STATE_BUCKET}"
  exit 0
fi

echo "Creating state bucket gs://${STATE_BUCKET} (${REGION})"
gcloud storage buckets create "gs://${STATE_BUCKET}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --uniform-bucket-level-access
gcloud storage buckets update "gs://${STATE_BUCKET}" --versioning
echo "Created gs://${STATE_BUCKET}"
