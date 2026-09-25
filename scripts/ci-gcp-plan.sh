#!/usr/bin/env bash
# CI / release gate: remote state init + plan all stacks (WIF auth must be active).
set -euo pipefail

ENV="${1:?Usage: ci-gcp-plan.sh <dev|qa|test|prod>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export TF_PLAN_DIR="${TF_PLAN_DIR:-${RUNNER_TEMP:-/tmp}/tf-plans-${ENV}}"

echo "=== GCP Terraform plan (${ENV}) ==="
"${SCRIPT_DIR}/infra-preflight.sh" "${ENV}" || true

set +e
"${SCRIPT_DIR}/tf-plan-all.sh" "${ENV}"
ec=$?
set -e

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "TF_PLAN_DIR=${TF_PLAN_DIR}" >>"${GITHUB_ENV}"
fi

# 0 = no changes, 2 = changes pending (both OK for CI)
if [[ "${ec}" -eq 1 ]]; then
  exit 1
fi
exit 0
