#!/usr/bin/env bash
# Remove a stale Terraform GCS state lock (after cancelled CI or crashed local run).
set -euo pipefail

ENV="${1:?Usage: state-unlock.sh <dev|qa|test|prod> <stack> [lock-id]}"
STACK="${2:?stack name}"
LOCK_ID="${3:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAST="${ROOT}/fast"
ENV_TFVARS="${FAST}/datasets/${ENV}/env.tfvars"
STATE_BUCKET="$(grep '^state_bucket' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
BACKEND_HCL="${FAST}/backends/${ENV}/${STACK}.hcl"

case "${STACK}" in
  project_services|cloud_storage|github_wif) STAGE="0-bootstrap" ;;
  network) STAGE="1-network" ;;
  gke|cloudsql|pubsub|cloudrun) STAGE="2-platform" ;;
  *) echo "Unknown stack: ${STACK}"; exit 1 ;;
esac

DIR="${FAST}/stages/${STAGE}/${STACK}"
cd "${DIR}"
terraform init -reconfigure -input=false -backend-config="${BACKEND_HCL}" >/dev/null

if [[ -n "${LOCK_ID}" ]]; then
  terraform force-unlock -force "${LOCK_ID}"
  echo "Force-unlocked ${LOCK_ID} on ${ENV}/${STACK}"
  exit 0
fi

LOCK_PATH="gs://${STATE_BUCKET}/${ENV}/${STACK}/default.tflock"
echo "Deleting stale lock object: ${LOCK_PATH}"
if gcloud storage rm "${LOCK_PATH}" 2>/dev/null; then
  echo "Removed ${LOCK_PATH}"
else
  echo "No lock file at ${LOCK_PATH} (or already cleared)."
fi
