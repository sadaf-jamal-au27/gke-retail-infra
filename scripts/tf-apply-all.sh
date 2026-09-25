#!/usr/bin/env bash
set -euo pipefail

ENV="${1:?Usage: tf-apply-all.sh <dev|qa|test|prod> [plan|apply|destroy]}"
ACTION="${2:-plan}"

STACKS=(
  project_services
  cloud_storage
  github_wif
  network
  gke
  cloudsql
  pubsub
  cloudrun
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for stack in "${STACKS[@]}"; do
  echo "==== FAST ${ENV}/${stack}: terraform ${ACTION} ===="
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" init
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${stack}" "${ACTION}"
done

echo "Done: ${ENV} ${ACTION}"
