terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }
  }

  # Uncomment and set organization/workspace to connect this stack to HCP Terraform
  # for speculative plans, native cost estimates, and the post-plan run task.
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
