# Steady-state API fleet. These are the machines the N2 resource-based commitment
# in commitments.tf is sized against: 3 x n2-standard-8 == 24 vCPU / 96 GB.
resource "google_compute_instance" "api" {
  count = var.api_node_count

  name         = "demo-app-${var.environment}-api-${count.index + 1}"
  machine_type = "n2-standard-8"
  zone         = var.zone
  labels       = merge(local.common_labels, { role = "api" })

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 100
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
  }

  service_account {
    email  = google_service_account.api.email
    scopes = ["cloud-platform"]
  }
}

# Async workers. Deliberately left outside the commitment so there is always some
# on-demand N2 spend for coverage reporting to show as uncovered.
resource "google_compute_instance" "worker" {
  count = var.worker_node_count

  name         = "demo-app-${var.environment}-worker-${count.index + 1}"
  machine_type = "n2-standard-4"
  zone         = var.zone
  labels       = merge(local.common_labels, { role = "worker" })

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 50
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
  }

  service_account {
    email  = google_service_account.api.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_disk" "api_data" {
  count = var.api_node_count

  name   = "demo-app-${var.environment}-api-data-${count.index + 1}"
  type   = "pd-ssd"
  zone   = var.zone
  size   = 750
  labels = local.common_labels
}

resource "google_compute_attached_disk" "api_data" {
  count = var.api_node_count

  disk     = google_compute_disk.api_data[count.index].id
  instance = google_compute_instance.api[count.index].id
}

resource "google_service_account" "api" {
  account_id   = "demo-app-${var.environment}-api"
  display_name = "demo-app-service ${var.environment} API"
}
