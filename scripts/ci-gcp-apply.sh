#!/usr/bin/env bash
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
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" init
  if [[ -f "${plan_file}" ]]; then
    export TF_PLAN_IN="${plan_file}"
    "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" apply
    unset TF_PLAN_IN
  else
    echo "No plan file for ${stack} (no changes) — skipping apply."
  fi
done

echo "Deploy complete: ${ENV}"
