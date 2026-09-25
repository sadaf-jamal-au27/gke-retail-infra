#!/usr/bin/env bash
set -euo pipefail

ENV="${1:?Usage: tf-apply-all.sh <dev|qa|test|prod> [plan|apply|destroy]}"
ACTION="${2:-plan}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/tf-stacks.sh"

if [[ "${ACTION}" == "plan" ]]; then
  exec "${SCRIPT_DIR}/tf-plan-all.sh" "${ENV}"
fi

for stack in "${STACKS[@]}"; do
  echo "==== FAST ${ENV}/${stack}: terraform ${ACTION} ===="
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" init
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" "${ACTION}"
done

echo "Done: ${ENV} ${ACTION}"
