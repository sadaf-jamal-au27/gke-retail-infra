#!/usr/bin/env bash
# Unit tests: fmt check, validate all FAST stacks (no GCP credentials).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAST="${ROOT}/fast"
ENV="${1:-dev}"
ENV_TFVARS="${FAST}/datasets/${ENV}/env.tfvars"

echo "=== FAST unit tests (env=${ENV}) ==="

if ! terraform fmt -check -recursive "${FAST}/modules" "${FAST}/stages"; then
  echo ""
  echo "Terraform fmt check failed. Fix locally:"
  echo "  terraform fmt -recursive ${FAST}/modules ${FAST}/stages"
  terraform fmt -check -recursive -diff "${FAST}/modules" "${FAST}/stages" || true
  exit 3
fi

while IFS= read -r dir; do
  stack="$(basename "${dir}")"
  echo "-- validate ${stack} --"
  dataset_tfvars="${FAST}/datasets/${ENV}/${stack}.tfvars"
  (
    cd "${dir}"
    terraform init -backend=false -input=false >/dev/null
    args=(-var-file="${ENV_TFVARS}")
    if [[ -f "${dataset_tfvars}" ]]; then
      args+=(-var-file="${dataset_tfvars}")
    fi
    if [[ "${stack}" == "cloudsql" ]]; then
      args+=(-var="database_password=unit-test-only")
    fi
    terraform validate
  )
done < <(find "${FAST}/stages" -mindepth 2 -maxdepth 2 -type d | sort)

if [[ -d "${ROOT}/tests/unit" ]]; then
  echo "-- terraform test (unit) --"
  (
    cd "${ROOT}/tests/unit"
    terraform init -backend=false -input=false >/dev/null
    terraform test
  )
fi

echo "Unit tests passed."
