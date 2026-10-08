resource "google_compute_firewall" "allow_health_checks" {
  name    = "demo-app-${var.environment}-allow-health-checks"
  network = google_compute_network.main.name

  direction     = "INGRESS"
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["demo-app-api"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "demo-app-${var.environment}-allow-internal"
  network = google_compute_network.main.name

  direction     = "INGRESS"
  source_ranges = ["10.20.0.0/20", "10.21.0.0/16", "10.22.0.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["443", "5432", "6379", "8080"]
  }
}

resource "google_compute_global_address" "private_services" {
  name          = "demo-app-${var.environment}-private-services"
  purpose       = "VPC_PEERING"
  address_type   = "INTERNAL"
  prefix_length  = 16
  network       = google_compute_network.main.id
}
