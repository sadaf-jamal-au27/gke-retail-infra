#!/usr/bin/env bash
# Quick preflight before Terraform plan/apply (local or CI with WIF).
set -euo pipefail

ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_TFVARS="${ROOT}/fast/datasets/${ENV}/env.tfvars"

echo "=== Infra preflight (${ENV}) ==="

if ! command -v terraform >/dev/null; then
  echo "FAIL: terraform not installed"
  exit 1
fi

if [[ ! -f "${ENV_TFVARS}" ]]; then
  echo "FAIL: missing ${ENV_TFVARS}"
  exit 1
fi

PROJECT_ID="$(grep '^project_id' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
echo "Terraform dataset: ${ENV}"
echo "GCP project:         ${PROJECT_ID}"

if command -v gcloud >/dev/null; then
  ACTIVE="$(gcloud config get-value project 2>/dev/null || true)"
  echo "gcloud project:      ${ACTIVE}"
  STATE_BUCKET="${PROJECT_ID}-retail-tfstate-${ENV}"
  if gcloud storage buckets describe "gs://${STATE_BUCKET}" >/dev/null 2>&1; then
    echo "OK: state bucket gs://${STATE_BUCKET}"
  else
    echo "WARN: state bucket missing — run ./scripts/gcp-bootstrap.sh ${ENV}"
  fi
else
  echo "NOTE: gcloud not in PATH (OK in CI after google-github-actions/auth)"
fi

if [[ -z "${TF_VAR_database_password:-}" ]]; then
  echo "WARN: TF_VAR_database_password not set (required for cloudsql plan/apply)"
else
  echo "OK: TF_VAR_database_password is set"
fi

echo "Preflight done."
