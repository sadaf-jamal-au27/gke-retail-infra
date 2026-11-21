#!/usr/bin/env bash
# One-time Owner grants. CI cannot do this (403 setIamPolicy on project / AR).
# Usage: grant-gke-node-sa-iam.sh [dev|qa|test|prod]
set -euo pipefail

ENV="${1:-dev}"
PROJECT="${GCP_PROJECT_ID:-ai-rag-agent-project}"
REGION="${GCP_REGION:-asia-south1}"
NODE_SA="gke-node-${ENV}@${PROJECT}.iam.gserviceaccount.com"

PROJECT_NUMBER="$(gcloud projects describe "${PROJECT}" --format='value(projectNumber)')"
DEFAULT_COMPUTE="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

echo "Granting project roles to ${NODE_SA} (run as Owner / Project IAM Admin)"
for role in \
  roles/logging.logWriter \
  roles/monitoring.metricWriter \
  roles/autoscaling.metricsWriter \
  roles/stackdriver.resourceMetadata.writer
do
  gcloud projects add-iam-policy-binding "${PROJECT}" \
    --member="serviceAccount:${NODE_SA}" \
    --role="${role}" \
    --condition=None \
    --quiet
done

echo "Granting Artifact Registry reader to node SA and default Compute SA"
for member in "${NODE_SA}" "${DEFAULT_COMPUTE}"; do
  gcloud artifacts repositories add-iam-policy-binding retail \
    --project="${PROJECT}" \
    --location="${REGION}" \
    --member="serviceAccount:${member}" \
    --role="roles/artifactregistry.reader" \
    --quiet
done

echo "Done. Autopilot still uses ${DEFAULT_COMPUTE} until the cluster is created with the custom node SA."
