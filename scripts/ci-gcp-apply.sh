#!/usr/bin/env bash
# Local / ad-hoc only. GitHub Actions uses .github/actions/terraform-fast (plan + apply).
# CI deploy: plan to files, then apply those exact plans (same job — no blind apply).
set -euo pipefail

ENV="${1:?Usage: ci-gcp-apply.sh <dev|qa|test|prod>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/tf-stacks.sh"

export TF_PLAN_DIR="${TF_PLAN_DIR:-${RUNNER_TEMP:-/tmp}/tf-plans-${ENV}}"
mkdir -p "${TF_PLAN_DIR}"

echo "=== GCP Terraform deploy (${ENV}): plan then apply ==="
"${SCRIPT_DIR}/infra-preflight.sh" "${ENV}" || true

echo "=== Adopt existing GCP resources into Terraform state (if any) ==="
"${SCRIPT_DIR}/tf.sh" "${ENV}" cloud_storage import-existing

set +e
"${SCRIPT_DIR}/tf-plan-all.sh" "${ENV}"
ec=$?
set -e
if [[ "${ec}" -eq 1 ]]; then
  exit 1
fi

for stack in "${STACKS[@]}"; do
  plan_file="${TF_PLAN_DIR}/${stack}.tfplan"
  echo "==== FAST ${ENV}/${stack}: apply plan ===="
  if [[ ! -f "${plan_file}" ]]; then
    echo "No plan file for ${stack} (no changes) — skipping apply."
    continue
  fi
  export TF_PLAN_IN="${plan_file}"
  set +e
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" apply
  ec=$?
  set -e
  unset TF_PLAN_IN
  if [[ "${ec}" -ne 0 ]]; then
    echo "Apply failed for ${stack} (exit ${ec})"
    exit 1
  fi
done

echo "Deploy complete: ${ENV}"
