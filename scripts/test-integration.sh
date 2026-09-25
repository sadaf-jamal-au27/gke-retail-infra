#!/usr/bin/env bash
# Integration tests: module-level terraform test + optional live plan (needs GCP auth).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV="${1:-dev}"

echo "=== FAST integration tests (env=${ENV}) ==="

"${ROOT}/scripts/test-unit.sh" "${ENV}"

MODULES=(
  project_services
  cloud_storage
  github_wif
  network
  gke
  cloudsql
  pubsub
  cloudrun
)

for mod in "${MODULES[@]}"; do
  dir="${ROOT}/tests/integration/modules/${mod}"
  [[ -d "${dir}" ]] || continue
  echo "-- integration module ${mod} --"
  (cd "${dir}" && terraform init -backend=false -input=false >/dev/null && terraform test)
done

echo "Integration tests passed."
