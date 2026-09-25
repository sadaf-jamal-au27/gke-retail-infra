#!/usr/bin/env bash
set -euo pipefail

ENV="${1:?Usage: tf.sh <dev|qa|test|prod> <stack> <init|plan|apply|destroy|output>}"
STACK="${2:?stack: project_services|cloud_storage|github_wif|network|gke|cloudsql|pubsub|cloudrun}"
ACTION="${3:-plan}"
shift 3 || true
EXTRA_ARGS=("$@")

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAST="${ROOT}/fast"

STAGE=""
case "${STACK}" in
  project_services|cloud_storage|github_wif) STAGE="0-bootstrap" ;;
  network) STAGE="1-network" ;;
  gke|cloudsql|pubsub|cloudrun) STAGE="2-platform" ;;
  *)
    echo "Unknown stack: ${STACK}"
    exit 1
    ;;
esac

DIR="${FAST}/stages/${STAGE}/${STACK}"
ENV_TFVARS="${FAST}/datasets/${ENV}/env.tfvars"
BACKEND_HCL="${FAST}/backends/${ENV}/${STACK}.hcl"
DATASET_STACK_TFVARS="${FAST}/datasets/${ENV}/${STACK}.tfvars"
LEGACY_STACK_TFVARS="${DIR}/${STACK}.tfvars"

if [[ ! -d "${DIR}" ]]; then
  echo "Missing ${DIR}. Run: node infra/scripts/generate-fast-stages.mjs"
  exit 1
fi

if [[ ! -f "${BACKEND_HCL}" ]]; then
  echo "Missing ${BACKEND_HCL}. Run: node infra/scripts/generate-fast-stages.mjs"
  exit 1
fi

cd "${DIR}"

if [[ ! -d .terraform ]] || [[ "${ACTION}" == "init" ]]; then
  terraform init -reconfigure -input=false -backend-config="${BACKEND_HCL}"
fi

if [[ "${ACTION}" == "init" ]]; then
  exit 0
fi

if [[ "${STACK}" == "cloudsql" ]] && [[ "${ACTION}" != "output" ]]; then
  if [[ -z "${TF_VAR_database_password:-}" ]]; then
    echo "ERROR: export TF_VAR_database_password before cloudsql plan/apply"
    exit 1
  fi
fi

# Required vars must be set for plan/apply/import (root module has no defaults).
VAR_ARGS=(-var-file="${ENV_TFVARS}")
if [[ -f "${DATASET_STACK_TFVARS}" ]]; then
  VAR_ARGS+=(-var-file="${DATASET_STACK_TFVARS}")
elif [[ -f "${LEGACY_STACK_TFVARS}" ]]; then
  echo "WARN: using legacy ${LEGACY_STACK_TFVARS} — move values to ${DATASET_STACK_TFVARS}" >&2
  VAR_ARGS+=(-var-file="${LEGACY_STACK_TFVARS}")
fi
SERVICE_ACCOUNT_TFVARS="${FAST}/datasets/${ENV}/service_account.tfvars"
if [[ "${STACK}" == "gke" ]] && [[ -f "${SERVICE_ACCOUNT_TFVARS}" ]]; then
  VAR_ARGS+=(-var-file="${SERVICE_ACCOUNT_TFVARS}")
fi
if [[ "${STACK}" == "cloudsql" ]] && [[ "${ACTION}" != "output" ]]; then
  VAR_ARGS+=(-var="database_password=${TF_VAR_database_password}")
fi

# Assets bucket may exist in GCP from a prior partial apply; import into state before plan/apply.
adopt_cloud_storage_assets() {
  local project_id bucket addr
  project_id="$(grep '^project_id' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
  bucket="${project_id}-retail-assets-${ENV}"
  addr="module.cloud_storage.google_storage_bucket.assets"
  if terraform state show -no-color "${addr}" >/dev/null 2>&1; then
    return 0
  fi
  if command -v gcloud >/dev/null 2>&1; then
    if ! gcloud storage buckets describe "gs://${bucket}" --project="${project_id}" >/dev/null 2>&1; then
      return 0
    fi
  else
    return 0
  fi
  echo "terraform import ${addr} ${bucket}"
  terraform import -input=false "${VAR_ARGS[@]}" "${addr}" "${bucket}"
}

if [[ "${STACK}" == "cloud_storage" ]]; then
  if [[ "${ACTION}" == "import-existing" ]]; then
    adopt_cloud_storage_assets
    exit 0
  fi
  if [[ "${ACTION}" == "plan" || "${ACTION}" == "apply" ]]; then
    adopt_cloud_storage_assets
  fi
fi

case "${ACTION}" in
  plan)
    extra=(-input=false -detailed-exitcode)
    if [[ -n "${TF_PLAN_OUT:-}" ]]; then
      extra+=(-out="${TF_PLAN_OUT}")
    fi
    # CI plan is read-only; -lock=false avoids stale locks when a run is cancelled mid-plan.
    if [[ "${TF_PLAN_LOCK:-true}" == "false" ]]; then
      extra+=(-lock=false)
    fi
    terraform plan "${VAR_ARGS[@]}" "${extra[@]}"
    ;;
  apply)
    if [[ -n "${TF_PLAN_IN:-}" ]]; then
      terraform apply -input=false "${TF_PLAN_IN}"
    else
      terraform apply "${VAR_ARGS[@]}" -input=false -auto-approve
    fi
    ;;
  destroy|refresh)
    extra=(-input=false)
    if [[ "${ACTION}" == "destroy" ]]; then
      extra+=(-auto-approve)
    fi
    terraform "${ACTION}" "${VAR_ARGS[@]}" "${extra[@]}"
    ;;
  output|validate|fmt)
    terraform "${ACTION}" "${EXTRA_ARGS[@]}"
    ;;
  *)
    terraform "${ACTION}" "${VAR_ARGS[@]}"
    ;;
esac
