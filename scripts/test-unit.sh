#!/usr/bin/env bash
# Unit tests: fmt check, validate all FAST stacks (no GCP credentials).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAST="${ROOT}/fast"
ENV="${1:-dev}"
ENV_TFVARS="${FAST}/datasets/${ENV}/env.tfvars"

echo "=== FAST unit tests (env=${ENV}) ==="

terraform fmt -check -recursive "${FAST}/modules" "${FAST}/stages"

while IFS= read -r dir; do
  stack="$(basename "${dir}")"
  echo "-- validate ${stack} --"
  (
    cd "${dir}"
    rm -rf .terraform
    terraform init -backend=false -input=false >/dev/null
    args=(-var-file="${ENV_TFVARS}")
    tfvars="${dir}/${stack}.tfvars"
    [[ -f "${tfvars}" ]] && args+=(-var-file="${tfvars}")
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
    rm -rf .terraform
    terraform init -backend=false -input=false >/dev/null
    terraform test
  )
fi

echo "Unit tests passed."
