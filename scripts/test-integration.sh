#!/usr/bin/env bash
# Module-level terraform test (mock providers). No GCP credentials.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV="${1:-dev}"

echo "=== Module integration tests (env=${ENV}) ==="

MODULES=(
  project_services
  cloud_storage
  github_wif
  network
  gke
  cloudsql
  pubsub
)

ran=0
for mod in "${MODULES[@]}"; do
  dir="${ROOT}/tests/integration/modules/${mod}"
  [[ -d "${dir}" ]] || continue
  ran=1
  echo "-- module test ${mod} --"
  (
    cd "${dir}"
    terraform init -backend=false -input=false >/dev/null
    terraform test
  )
done

if [[ -d "${ROOT}/tests/integration/platform" ]]; then
  ran=1
  echo "-- platform integration test --"
  (
    cd "${ROOT}/tests/integration/platform"
    terraform init -backend=false -input=false >/dev/null
    terraform test
  )
fi

if [[ "${ran}" -eq 0 ]]; then
  echo "No tests/integration suites found (skipped)."
fi

echo "Module integration tests passed."
