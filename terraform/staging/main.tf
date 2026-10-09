terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type    = string
  default = "pump-demo-staging"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

locals {
  common_labels = {
    environment = "staging"
    service     = "demo-app-service"
    managed_by  = "terraform"
  }
}

# Staging carries no commitments at all. Every machine here is on-demand, which
# makes it the control case against terraform/prod.
resource "google_compute_network" "main" {
  name                    = "demo-app-staging"
  auto_create_subnetworks = true
}

resource "google_compute_instance" "app" {
  name         = "demo-app-staging-app"
  machine_type = "e2-standard-4"
  zone         = var.zone
  labels       = local.common_labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 50
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = google_compute_network.main.id
  }
}

resource "google_sql_database_instance" "main" {
  name                = "demo-app-staging"
  database_version    = "POSTGRES_16"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = "db-custom-2-7680"
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = 50
    user_labels       = local.common_labels
  }
}

resource "google_storage_bucket" "artifacts" {
  name                        = "demo-app-staging-artifacts"
  location                    = "US"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = local.common_labels
}

# Usage-driven service; native TFC cost estimates may have limited coverage here.
resource "google_cloud_run_v2_service" "api" {
  name     = "demo-app-staging-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }
}
