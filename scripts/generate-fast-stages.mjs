#!/usr/bin/env node
/**
 * FAST landing zone: infra/fast/stages/<stage>/<stack>/ + datasets/<env>/env.tfvars
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const infraRoot = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const fastRoot = path.join(infraRoot, "fast");
const datasetsRoot = path.join(fastRoot, "datasets");
const stagesRoot = path.join(fastRoot, "stages");
const modulesRoot = path.join(fastRoot, "modules");
const scaffoldDir = path.join(modulesRoot, "_scaffold");
const legacyLive = path.join(fastRoot, "stages");

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

const STACKS = Object.values(STAGE_STACKS).flat();

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
  source      = "${mod}"
  project_id  = var.project_id
  region      = var.region
  env         = var.env
  github_org  = var.github_org
  github_repo = var.github_repo
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
module "gke" {
  source                  = "${mod}"
  project_id              = var.project_id
  region                  = var.region
  env                     = var.env
  network_name            = data.terraform_remote_state.network.outputs.network_name
  subnet_name             = data.terraform_remote_state.network.outputs.gke_subnet_name
  pods_range_name         = data.terraform_remote_state.network.outputs.pods_range_name
  services_range_name     = data.terraform_remote_state.network.outputs.services_range_name
  master_ipv4_cidr        = var.master_ipv4_cidr
  master_authorized_cidr  = var.master_authorized_cidr
  k8s_namespace           = var.k8s_namespace
  k8s_service_account     = var.k8s_service_account
}
`;
    case "cloudsql":
      return `${remoteStateNetwork()}
module "cloudsql" {
  source            = "${mod}"
  project_id        = var.project_id
  region            = var.region
  env               = var.env
  network_id        = data.terraform_remote_state.network.outputs.network_id
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
module "cloudrun" {
  source                = "${mod}"
  project_id            = var.project_id
  region                = var.region
  env                   = var.env
  bff_sa_email          = data.terraform_remote_state.gke.outputs.workload_gsa_email
  vpc_connector_id      = data.terraform_remote_state.network.outputs.serverless_connector_id
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
    .map(
      (o) => `output "${o}" {
  value = module.${name}.${o}
}
`
    )
    .join("\n");
}

function extraVariablesTf(stack) {
  switch (stack) {
    case "cloud_storage":
      return `variable "force_destroy" {
  type    = bool
  default = false
}
`;
    case "github_wif":
      return `variable "github_org" { type = string }
variable "github_repo" { type = string }
`;
    case "network":
      return `variable "gke_subnet_cidr" { type = string }
variable "pods_cidr" { type = string }
variable "services_cidr" { type = string }
variable "sql_subnet_cidr" { type = string }
variable "serverless_connector_cidr" { type = string }
`;
    case "gke":
      return `variable "master_ipv4_cidr" { type = string }
variable "master_authorized_cidr" { type = string }
variable "k8s_namespace" {
  type    = string
  default = "retail"
}
variable "k8s_service_account" {
  type    = string
  default = "retail-app"
}
`;
    case "cloudsql":
      return `variable "database_password" {
  type      = string
  sensitive = true
}
variable "tier" { type = string }
variable "availability_type" { type = string }
variable "disk_size_gb" { type = number }
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

github_org  = "REPLACE_GITHUB_ORG"
github_repo = "REPLACE_GITHUB_REPO"
`
    );
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

      const targetTfvars = path.join(stackDir, `${stack}.tfvars`);
      const legacyTfvars = path.join(stagesRoot, stage, stack, `${stack}.tfvars`);
      const fastTfvars = path.join(stagesRoot, stage, stack, `${stack}.tfvars`);
      if (!fs.existsSync(fastTfvars) && fs.existsSync(legacyTfvars)) {
        fs.copyFileSync(legacyTfvars, targetTfvars);
      } else if (!fs.existsSync(targetTfvars)) {
        fs.writeFileSync(targetTfvars, `# Overrides for ${stack}\n`);
      }
    }
  }
}

console.log("Generated infra/fast/stages/{0-bootstrap,1-network,2-platform}/<stack>/");
