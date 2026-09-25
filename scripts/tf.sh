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
STACK_TFVARS="${DIR}/${STACK}.tfvars"

if [[ ! -d "${DIR}" ]]; then
  echo "Missing ${DIR}. Run: node infra/scripts/generate-fast-stages.mjs"
  exit 1
fi

PROJECT_ID="$(grep '^project_id' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
STATE_BUCKET="${PROJECT_ID}-retail-tfstate-${ENV}"
PREFIX="${ENV}/${STACK}"

cd "${DIR}"

if [[ ! -d .terraform ]] || [[ "${ACTION}" == "init" ]]; then
  terraform init -reconfigure \
    -backend-config="bucket=${STATE_BUCKET}" \
    -backend-config="prefix=${PREFIX}"
fi

if [[ "${ACTION}" == "init" ]]; then
  exit 0
fi

DATASET_STACK_TFVARS="${FAST}/datasets/${ENV}/${STACK}.tfvars"

VAR_ARGS=(-var-file="${ENV_TFVARS}")
if [[ -f "${DATASET_STACK_TFVARS}" ]]; then
  VAR_ARGS+=(-var-file="${DATASET_STACK_TFVARS}")
fi
if [[ -f "${STACK_TFVARS}" ]]; then
  VAR_ARGS+=(-var-file="${STACK_TFVARS}")
fi

case "${ACTION}" in
  plan|apply|destroy|refresh)
    extra=(-input=false)
    if [[ "${ACTION}" == "apply" || "${ACTION}" == "destroy" ]]; then
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
