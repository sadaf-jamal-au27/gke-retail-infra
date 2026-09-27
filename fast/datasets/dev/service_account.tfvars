# GKE Workload Identity: K8s namespace + service account name (must match Helm).
# Live dev cluster currently binds: retail/retail-app
k8s_namespace       = "retail"
k8s_service_account = "retail-app"


# Already in GCP state — keep in config or terraform will destroy them.

# Secret Manager secret-level IAM (Terraform creates secrets + grants secretAccessor).
# Add secret versions in Console / gcloud after first apply.

secret_ids = [
  "retail-db-password",
  "retail-app-config",
]
