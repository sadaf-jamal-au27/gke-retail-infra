mock_provider "google" {}

run "cloud_storage_plan" {
  command = plan

  module {
    source = "../../../fast/modules/cloud_storage"
  }

  variables {
    project_id = "fast-integration-test"
    region     = "asia-south1"
    env        = "dev"
  }
}

run "github_wif_plan" {
  command = plan

  module {
    source = "../../../fast/modules/github_wif"
  }

  variables {
    project_id   = "fast-integration-test"
    region       = "asia-south1"
    env          = "dev"
    github_org   = "example-org"
    github_repos = ["example-repo"]
  }
}
