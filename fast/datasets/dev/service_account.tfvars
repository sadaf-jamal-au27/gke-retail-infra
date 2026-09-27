# GKE Workload Identity: K8s namespace + service account name (must match Helm).
# Live dev cluster currently binds: retail/retail-app
k8s_namespace       = "retail"
k8s_service_account = "retail-app"

# Already in GCP state — keep in config or terraform will destroy them.
secret_ids = [
  "retail-db-password",
  "retail-app-config",
]
