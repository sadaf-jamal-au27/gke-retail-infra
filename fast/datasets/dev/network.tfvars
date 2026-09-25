# VPC + subnets (edit per environment; defaults match retail dev sizing)
gke_subnet_cidr           = "10.10.0.0/20"
pods_cidr                 = "10.20.0.0/16"
services_cidr             = "10.30.0.0/20"
sql_subnet_cidr           = "10.11.0.0/24"
serverless_connector_cidr = "10.8.0.0/28"
