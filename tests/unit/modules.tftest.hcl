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
