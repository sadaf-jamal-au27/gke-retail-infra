#!/usr/bin/env node
/**
 * Regenerate FAST stage roots under infra/fast/stages/ from modules/.
 * Environment values live ONLY in fast/datasets/<env>/ — not under stages/.
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const infraRoot = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const fastRoot = path.join(infraRoot, "fast");
const datasetsRoot = path.join(fastRoot, "datasets");
const stagesRoot = path.join(fastRoot, "stages");
const backendsRoot = path.join(fastRoot, "backends");
const modulesRoot = path.join(fastRoot, "modules");
const scaffoldDir = path.join(modulesRoot, "_scaffold");

const scaffold = ["backend.tf", "versions.tf", "provider.tf"].map((f) =>
  fs.readFileSync(path.join(scaffoldDir, f), "utf8")
);

const ENVIRONMENTS = [
  { name: "dev", project_id: "ai-rag-agent-project" },
  { name: "qa", project_id: "REPLACE_GCP_QA_PROJECT" },
  { name: "test", project_id: "REPLACE_GCP_TEST_PROJECT" },
  { name: "prod", project_id: "REPLACE_GCP_PROD_PROJECT" },
];

const STAGE_STACKS = {
  "0-bootstrap": ["project_services", "cloud_storage", "github_wif"],
  "1-network": ["network"],
  "2-platform": ["gke", "cloudsql", "pubsub", "cloudrun"],
};

const ALL_STACKS = Object.values(STAGE_STACKS).flat();

function stateBucketForEnv(envName, projectId) {
  const envTfvars = path.join(datasetsRoot, envName, "env.tfvars");
  if (fs.existsSync(envTfvars)) {
    const match = fs.readFileSync(envTfvars, "utf8").match(/^state_bucket\s*=\s*"([^"]+)"/m);
    if (match) return match[1];
  }
  return `${projectId}-retail-tfstate-${envName}`;
}

const DEFAULT_GCP_SERVICES = `services = [
  "artifactregistry.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "compute.googleapis.com",
  "container.googleapis.com",
  "iam.googleapis.com",
  "iamcredentials.googleapis.com",
  "pubsub.googleapis.com",
  "run.googleapis.com",
  "secretmanager.googleapis.com",
  "servicenetworking.googleapis.com",
  "sqladmin.googleapis.com",
  "storage.googleapis.com",
]
`;

/** Default stack tfvars per environment (written once if file missing). */
const DATASET_STACK_DEFAULTS = {
  project_services: `# GCP APIs — edit list per environment\n${DEFAULT_GCP_SERVICES}`,
  cloud_storage: "force_destroy     = true\nenable_versioning = true\n",
  github_wif: `github_org = "sadaf-jamal-au27"
github_repos = [
  "gke-retail-infra",
  "gke-retail-application",
  "gke-retail-devops",
  "gke-microservices",
]
pool_id     = "github-pool"
provider_id = "github-provider"
`,
  network: `gke_subnet_cidr           = "10.10.0.0/20"
pods_cidr                 = "10.20.0.0/16"
services_cidr             = "10.30.0.0/20"
sql_subnet_cidr           = "10.11.0.0/24"
serverless_connector_cidr = "10.8.0.0/28"
`,
  gke: `master_ipv4_cidr       = "172.16.0.0/28"
master_authorized_cidr = "0.0.0.0/0"
`,
  cloudsql: `tier              = "db-custom-1-3840"
availability_type = "ZONAL"
disk_size_gb      = 20
`,
  pubsub: "# Topic names use module defaults\n",
  cloudrun: "allow_unauthenticated = true\n",
};

const SERVICE_ACCOUNT_DEFAULTS = {
  dev: `# GKE Workload Identity (must match Helm namespace + KSA)
k8s_namespace       = "retail"
k8s_service_account = "retail-app"

# Secret Manager secret-level IAM (created + secretAccessor for workload SA)
secret_ids = [
  "retail-db-password",
  "retail-app-config",
]
`,
  qa: `k8s_namespace       = "retail-qa"
k8s_service_account = "retail-app"
secret_ids          = ["retail-db-password", "retail-app-config"]
`,
  test: `k8s_namespace       = "retail-test"
k8s_service_account = "retail-app"
secret_ids          = ["retail-db-password", "retail-app-config"]
`,
  prod: `k8s_namespace       = "retail-prod"
k8s_service_account = "retail-app"
secret_ids          = ["retail-db-password", "retail-app-config"]
`,
};

const commonVariablesTf = `variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "env" {
  type = string
}

variable "state_bucket" {
  type        = string
  description = "GCS bucket holding remote state for stack dependencies."
}
`;

function remoteStateNetwork() {
  return `
data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "\${var.env}/network"
  }
}
`;
}

function remoteStateGke() {
  return `
data "terraform_remote_state" "gke" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "\${var.env}/gke"
  }
}
`;
}

function mainTf(stack) {
  const mod = `../../../modules/${stack}`;
  switch (stack) {
    case "project_services":
      return `
module "project_services" {
  source     = "${mod}"
  project_id = var.project_id
  region     = var.region
  services   = var.services
}
`;
    case "cloud_storage":
      return `
module "cloud_storage" {
  source        = "${mod}"
  project_id    = var.project_id
  region        = var.region
  env           = var.env
  force_destroy = var.force_destroy
}
`;
    case "github_wif":
      return `
module "github_wif" {
  source             = "${mod}"
  project_id         = var.project_id
  region             = var.region
  env                = var.env
  github_org         = var.github_org
  github_repos       = var.github_repos
  pool_id            = var.pool_id
  provider_id        = var.provider_id
  state_bucket_name  = var.state_bucket
  assets_bucket_name = "\${var.project_id}-retail-assets-\${var.env}"
}
`;
    case "network":
      return `
module "network" {
  source                    = "${mod}"
  project_id                = var.project_id
  region                    = var.region
  env                       = var.env
  gke_subnet_cidr           = var.gke_subnet_cidr
  pods_cidr                 = var.pods_cidr
  services_cidr             = var.services_cidr
  sql_subnet_cidr           = var.sql_subnet_cidr
  serverless_connector_cidr = var.serverless_connector_cidr
}
`;
    case "gke":
      return `${remoteStateNetwork()}
locals {
  network_name          = try(data.terraform_remote_state.network.outputs.network_name, null)
  gke_subnet_name       = try(data.terraform_remote_state.network.outputs.gke_subnet_name, null)
  pods_range_name       = try(data.terraform_remote_state.network.outputs.pods_range_name, null)
  services_range_name   = try(data.terraform_remote_state.network.outputs.services_range_name, null)
  network_outputs_ready = local.network_name != null
}

module "gke" {
  count = local.network_outputs_ready ? 1 : 0

  source                 = "${mod}"
  project_id             = var.project_id
  region                 = var.region
  env                    = var.env
  network_name           = local.network_name
  subnet_name            = local.gke_subnet_name
  pods_range_name        = local.pods_range_name
  services_range_name    = local.services_range_name
  master_ipv4_cidr       = var.master_ipv4_cidr
  master_authorized_cidr = var.master_authorized_cidr
  k8s_namespace          = var.k8s_namespace
  k8s_service_account    = var.k8s_service_account
  assets_bucket_name     = var.assets_bucket_name
  secret_ids             = var.secret_ids
}
`;
    case "cloudsql":
      return `${remoteStateNetwork()}
locals {
  network_id            = try(data.terraform_remote_state.network.outputs.network_id, null)
  network_outputs_ready = local.network_id != null
}

module "cloudsql" {
  count = local.network_outputs_ready ? 1 : 0

  source            = "${mod}"
  project_id        = var.project_id
  region            = var.region
  env               = var.env
  network_id        = local.network_id
  database_password = var.database_password
  tier              = var.tier
  availability_type = var.availability_type
  disk_size_gb      = var.disk_size_gb
}
`;
    case "pubsub":
      return `
module "pubsub" {
  source     = "${mod}"
  project_id = var.project_id
  region     = var.region
  env        = var.env
}
`;
    case "cloudrun":
      return `${remoteStateNetwork()}${remoteStateGke()}
locals {
  vpc_connector_id     = try(data.terraform_remote_state.network.outputs.serverless_connector_id, null)
  workload_gsa_email   = try(data.terraform_remote_state.gke.outputs.workload_gsa_email, null)
  cloudrun_ready       = local.vpc_connector_id != null && local.workload_gsa_email != null
}

module "cloudrun" {
  count = local.cloudrun_ready ? 1 : 0

  source                = "${mod}"
  project_id            = var.project_id
  region                = var.region
  env                   = var.env
  bff_sa_email          = local.workload_gsa_email
  vpc_connector_id      = local.vpc_connector_id
  allow_unauthenticated = var.allow_unauthenticated
}
`;
    default:
      throw new Error(`Unknown stack: ${stack}`);
  }
}

function outputsTf(stack) {
  const name = stack;
  const map = {
    project_services: ["enabled_services"],
    cloud_storage: ["assets_bucket_name", "terraform_state_bucket_name"],
    github_wif: ["workload_identity_provider", "ci_service_account_email", "workload_identity_pool_name"],
    network: ["network_id", "network_name", "gke_subnet_name", "pods_range_name", "services_range_name", "serverless_connector_id"],
    gke: ["cluster_name", "artifact_registry_url", "workload_gsa_email", "cluster_location"],
    cloudsql: ["instance_connection_name", "instance_name"],
    pubsub: ["topic_names"],
    cloudrun: ["bff_url", "bff_name"],
  };
  return (map[stack] ?? [])
    .map((o) => {
      const usesCount = ["gke", "cloudsql", "cloudrun"].includes(stack);
      const ref = usesCount
        ? `try(module.${name}[0].${o}, null)`
        : `module.${name}.${o}`;
      return `output "${o}" {
  value = ${ref}
}
`;
    })
    .join("\n");
}

function extraVariablesTf(stack) {
  switch (stack) {
    case "project_services":
      return `variable "services" {
  type = list(string)
  default = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
  ]
}
`;
    case "cloud_storage":
      return `variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}
`;
    case "github_wif":
      return `variable "github_org" { type = string }

variable "github_repos" {
  type = list(string)
}

variable "pool_id" {
  type    = string
  default = "github-pool"
}

variable "provider_id" {
  type    = string
  default = "github-provider"
}
`;
    case "network":
      return `variable "gke_subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}
variable "pods_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "services_cidr" {
  type    = string
  default = "10.30.0.0/20"
}
variable "sql_subnet_cidr" {
  type    = string
  default = "10.11.0.0/24"
}
variable "serverless_connector_cidr" {
  type    = string
  default = "10.8.0.0/28"
}
`;
    case "gke":
      return `variable "master_ipv4_cidr" {
  type    = string
  default = "172.16.0.0/28"
}
variable "master_authorized_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
variable "k8s_namespace" {
  type    = string
  default = "retail"
}
variable "k8s_service_account" {
  type    = string
  default = "retail-app"
}
variable "assets_bucket_name" {
  type    = string
  default = null
}
variable "secret_ids" {
  type    = list(string)
  default = []
}
`;
    case "cloudsql":
      return `variable "database_password" {
  type      = string
  sensitive = true
}
variable "tier" {
  type    = string
  default = "db-custom-1-3840"
}
variable "availability_type" {
  type    = string
  default = "ZONAL"
}
variable "disk_size_gb" {
  type    = number
  default = 20
}
`;
    case "cloudrun":
      return `variable "allow_unauthenticated" {
  type    = bool
  default = false
}
`;
    default:
      return "";
  }
}

for (const env of ENVIRONMENTS) {
  const envDir = path.join(datasetsRoot, env.name);
  fs.mkdirSync(envDir, { recursive: true });

  const existing = path.join(envDir, "env.tfvars");
  if (!fs.existsSync(existing)) {
    fs.writeFileSync(
      existing,
      `project_id   = "${env.project_id}"
region       = "asia-south1"
env          = "${env.name}"
state_bucket = "${env.project_id}-retail-tfstate-${env.name}"
`
    );
  }

  for (const [stack, body] of Object.entries(DATASET_STACK_DEFAULTS)) {
    const stackTfvars = path.join(envDir, `${stack}.tfvars`);
    if (!fs.existsSync(stackTfvars)) {
      fs.writeFileSync(stackTfvars, body);
    }
  }

  const saTfvars = path.join(envDir, "service_account.tfvars");
  if (!fs.existsSync(saTfvars)) {
    fs.writeFileSync(
      saTfvars,
      SERVICE_ACCOUNT_DEFAULTS[env.name] ??
        `k8s_namespace       = "retail-${env.name}"
k8s_service_account = "retail-app"
`
    );
  }
}

for (const env of ENVIRONMENTS) {
  const bucket = stateBucketForEnv(env.name, env.project_id);
  const backendDir = path.join(backendsRoot, env.name);
  fs.mkdirSync(backendDir, { recursive: true });
  for (const stack of ALL_STACKS) {
    const hcl = `# Remote state for stack "${stack}" (env: ${env.name})
# Regenerate: node infra/scripts/generate-fast-stages.mjs
# Must match state_bucket in datasets/${env.name}/env.tfvars

bucket = "${bucket}"
prefix = "${env.name}/${stack}"
`;
    fs.writeFileSync(path.join(backendDir, `${stack}.hcl`), hcl);
  }
}

for (const [stage, stacks] of Object.entries(STAGE_STACKS)) {
  for (const stack of stacks) {
    const stackDir = path.join(stagesRoot, stage, stack);
    fs.mkdirSync(stackDir, { recursive: true });

    fs.writeFileSync(path.join(stackDir, "backend.tf"), scaffold[0]);
    fs.writeFileSync(path.join(stackDir, "versions.tf"), scaffold[1]);
    fs.writeFileSync(path.join(stackDir, "provider.tf"), scaffold[2]);
    fs.writeFileSync(path.join(stackDir, "variables.tf"), commonVariablesTf + extraVariablesTf(stack));
    fs.writeFileSync(path.join(stackDir, "main.tf"), mainTf(stack).trim() + "\n");
    fs.writeFileSync(path.join(stackDir, "outputs.tf"), outputsTf(stack));

    const legacyTfvars = path.join(stackDir, `${stack}.tfvars`);
    if (fs.existsSync(legacyTfvars)) {
      fs.writeFileSync(
        legacyTfvars,
        `# DEPRECATED: edit fast/datasets/<env>/${stack}.tfvars instead.\n`
      );
    }
  }
}

const datasetsReadme = `# Environment datasets (single source of truth)

Edit values here — not \`stages/**/<stack>.tfvars\`.

| File | Purpose |
|------|---------|
| \`env.tfvars\` | project_id, region, env, state_bucket |
| \`<stack>.tfvars\` | Stack-specific sizing, CIDRs, GitHub org/repos |
| \`service_account.tfvars\` | GKE Workload Identity (used by \`gke\` stack) |

Remote state bucket/prefix: **\`fast/backends/<env>/<stack>.hcl\`** (generated; keep in sync with \`state_bucket\` here).

See \`docs/FAST_STRUCTURE.md\`.
`;
fs.writeFileSync(path.join(datasetsRoot, "README.md"), datasetsReadme);

const backendsReadme = `# Terraform GCS backend config (generated)

One \`.hcl\` per stack per environment. Used by \`tf.sh\`:

\`\`\`bash
terraform init -backend-config=../../backends/dev/gke.hcl
\`\`\`

| Path | Meaning |
|------|---------|
| \`backends/<env>/<stack>.hcl\` | \`bucket\` + \`prefix\` for that stack's state |

**Source of truth for bucket name:** \`datasets/<env>/env.tfvars\` → \`state_bucket\`.

After changing \`state_bucket\`, run \`node infra/scripts/generate-fast-stages.mjs\`.

Stage roots only declare \`backend "gcs" {}\` in \`backend.tf\` — settings live here.
`;
fs.writeFileSync(path.join(backendsRoot, "README.md"), backendsReadme);

try {
  execSync(`terraform fmt -recursive "${modulesRoot}" "${stagesRoot}"`, {
    stdio: "inherit",
  });
} catch {
  console.warn(
    "Warning: terraform fmt failed (install Terraform 1.x to format generated stages)."
  );
}

console.log("Generated stages, backends/*.hcl, and dataset templates.");
