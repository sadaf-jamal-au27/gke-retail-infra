#!/usr/bin/env bash
# Quick preflight before Terraform apply.
set -euo pipefail

ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_TFVARS="${ROOT}/fast/datasets/${ENV}/env.tfvars"

echo "=== Infra preflight (${ENV}) ==="

if ! command -v gcloud >/dev/null; then
  echo "FAIL: gcloud not installed"
  exit 1
fi
if ! command -v terraform >/dev/null; then
  echo "FAIL: terraform not installed"
  exit 1
fi

if [[ ! -f "${ENV_TFVARS}" ]]; then
  echo "FAIL: missing ${ENV_TFVARS}"
  exit 1
fi

PROJECT_ID="$(grep '^project_id' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2)"
ACTIVE="$(gcloud config get-value project 2>/dev/null || true)"
echo "GCP project (env.tfvars): ${PROJECT_ID}"
echo "GCP project (gcloud):     ${ACTIVE}"

if [[ "${ACTIVE}" != "${PROJECT_ID}" ]]; then
  echo "WARN: gcloud project differs — run: gcloud config set project ${PROJECT_ID}"
fi

STATE_BUCKET="${PROJECT_ID}-retail-tfstate-${ENV}"
if gcloud storage buckets describe "gs://${STATE_BUCKET}" >/dev/null 2>&1; then
  echo "OK: state bucket gs://${STATE_BUCKET}"
else
  echo "MISSING: state bucket — run ./scripts/gcp-bootstrap.sh ${ENV}"
fi

GITHUB_ORG="$(grep '^github_org' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2 || true)"
GITHUB_REPO="$(grep '^github_repo' "${ENV_TFVARS}" | head -1 | cut -d'"' -f2 || true)"
if [[ "${GITHUB_ORG}" == REPLACE_* || -z "${GITHUB_ORG}" ]]; then
  echo "WARN: github_org not set (needed for github_wif apply)"
else
  echo "OK: github_org=${GITHUB_ORG} github_repo=${GITHUB_REPO}"
fi

if [[ -z "${TF_VAR_database_password:-}" ]]; then
  echo "WARN: TF_VAR_database_password not set (required for cloudsql plan/apply)"
else
  echo "OK: TF_VAR_database_password is set"
fi

echo ""
echo "Next: ./scripts/tf-apply-all.sh ${ENV} plan"
echo "Guide: docs/INFRA_SETUP.md"
