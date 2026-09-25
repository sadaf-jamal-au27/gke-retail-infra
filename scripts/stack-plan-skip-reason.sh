#!/usr/bin/env bash
# Return 0 if stack plan should be skipped (dependency state not applied yet).
set -euo pipefail

ENV="${1:?}"
STACK="${2:?}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

remote_has_output() {
  local dep_stack="$1"
  local output_name="$2"
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${dep_stack}" init >/dev/null 2>&1
  "${SCRIPT_DIR}/tf.sh" "${ENV}" "${dep_stack}" output -raw "${output_name}" >/dev/null 2>&1
}

case "${STACK}" in
  gke|cloudsql|pubsub)
    if ! remote_has_output network network_name; then
      echo "network not applied yet (no remote outputs) — apply: ./infra/scripts/tf.sh ${ENV} network apply"
      exit 0
    fi
    ;;
  cloudrun)
    if ! remote_has_output network network_name; then
      echo "network not applied yet"
      exit 0
    fi
    if ! remote_has_output gke cluster_name; then
      echo "gke not applied yet"
      exit 0
    fi
    ;;
esac

exit 1
