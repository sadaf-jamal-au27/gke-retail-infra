/**
 * Retail landing zone network — Cloud Foundation Fabric net-vpc + serverless connector.
 * @see https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/net-vpc
 */
locals {
  vpc_name   = "retail-${var.env}-vpc"
  gke_subnet = "retail-${var.env}-gke"
  sql_subnet = "retail-${var.env}-sql"
}

module "vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v39.0.0"
  project_id = var.project_id
  name       = local.vpc_name

  subnets = [
    {
      name          = local.gke_subnet
      ip_cidr_range = var.gke_subnet_cidr
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.pods_cidr
        services = var.services_cidr
      }
    },
    {
      name          = local.sql_subnet
      ip_cidr_range = var.sql_subnet_cidr
      region        = var.region
    },
  ]

  psa_configs = [
    {
      ranges = {
        retail-sql-psa = "10.40.0.0/16"
      }
      range_prefix     = "retail-${var.env}-psa"
      service_producer = "servicenetworking.googleapis.com"
    },
  ]
}

resource "google_vpc_access_connector" "serverless" {
  name          = "retail-${var.env}-conn"
  region        = var.region
  network       = module.vpc.name
  ip_cidr_range = var.serverless_connector_cidr
  min_instances = 2
  max_instances = 3
}
