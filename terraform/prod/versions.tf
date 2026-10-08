terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }
  }

  # Terraform Cloud backend is intentionally commented out so that `terraform init`
  # and `infracost breakdown` work with no credentials. Uncomment to exercise the
  # HCP Terraform speculative-plan / run-task path instead of the Infracost CI path.
  #
  # cloud {
  #   organization = "pump-demo"
  #   workspaces {
  #     name = "demo-app-service-prod"
  #   }
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
