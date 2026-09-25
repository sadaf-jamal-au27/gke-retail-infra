#!/usr/bin/env bash
# Init + plan every stack; optional saved plan files (TF_PLAN_DIR).
set -euo pipefail

ENV="${1:?Usage: tf-plan-all.sh <dev|qa|test|prod>}"
PLAN_DIR="${TF_PLAN_DIR:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/tf-stacks.sh"

if [[ -n "${PLAN_DIR}" ]]; then
  mkdir -p "${PLAN_DIR}"
  echo "Plan files: ${PLAN_DIR}"
fi

overall=0
for stack in "${STACKS[@]}"; do
  echo "==== FAST ${ENV}/${stack}: init + plan ===="
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" init

  if [[ -n "${PLAN_DIR}" ]]; then
    export TF_PLAN_OUT="${PLAN_DIR}/${stack}.tfplan"
  else
    unset TF_PLAN_OUT
  fi

  set +e
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" plan
  ec=$?
  set -e
  if [[ "${ec}" -eq 1 ]]; then
    exit 1
  fi
  if [[ "${ec}" -eq 2 ]]; then
    overall=2
    echo "Planned changes: ${stack}"
  fi
done

if [[ "${overall}" -eq 2 ]]; then
  echo "Plan complete: changes pending for one or more stacks."
  exit 2
fi
echo "Plan complete: no changes."
exit 0
