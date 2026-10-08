locals {
  common_labels = {
    environment = var.environment
    service     = "demo-app-service"
    managed_by  = "terraform"
  }
}

resource "google_compute_network" "main" {
  name                    = "demo-app-${var.environment}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "demo-app-${var.environment}-${var.region}"
  network       = google_compute_network.main.id
  region        = var.region
  ip_cidr_range = "10.20.0.0/20"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.21.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.22.0.0/20"
  }
}

resource "google_compute_router" "main" {
  name    = "demo-app-${var.environment}"
  region  = var.region
  network = google_compute_network.main.id
}

# Cloud NAT is a recurring hourly + per-GB cost and is never commitment-covered.
resource "google_compute_router_nat" "main" {
  name                               = "demo-app-${var.environment}"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_address" "nat" {
  name   = "demo-app-${var.environment}-nat"
  region = var.region
}

resource "google_compute_global_address" "ingress" {
  name = "demo-app-${var.environment}-ingress"
}
