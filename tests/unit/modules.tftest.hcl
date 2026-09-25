mock_provider "google" {}

run "project_services_plan" {
  command = plan

  module {
    source = "../../fast/modules/project_services"
  }

  variables {
    project_id = "fast-unit-test"
    region     = "asia-south1"
  }
}

run "cloud_storage_plan" {
  command = plan

  module {
    source = "../../fast/modules/cloud_storage"
  }

  variables {
    project_id = "fast-unit-test"
    region     = "asia-south1"
    env        = "dev"
  }
}
