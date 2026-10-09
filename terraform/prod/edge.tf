# Public ingress for the API fleet. Adds forwarding-rule and proxy hourly cost that
# TFC native estimates surface separately from compute.
resource "google_compute_health_check" "api" {
  name = "demo-app-${var.environment}-api"

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }
}

resource "google_compute_backend_service" "api" {
  name                  = "demo-app-${var.environment}-api"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.api.id]

  backend {
    group = google_compute_instance_group.api.self_link
  }
}

resource "google_compute_instance_group" "api" {
  name = "demo-app-${var.environment}-api"
  zone = var.zone

  instances = google_compute_instance.api[*].self_link

  named_port {
    name = "http"
    port = 8080
  }
}

resource "google_compute_url_map" "api" {
  name            = "demo-app-${var.environment}-api"
  default_service = google_compute_backend_service.api.id
}

resource "google_compute_target_https_proxy" "api" {
  name             = "demo-app-${var.environment}-api"
  url_map          = google_compute_url_map.api.id
  ssl_certificates = [google_compute_managed_ssl_certificate.api.id]
}

resource "google_compute_managed_ssl_certificate" "api" {
  name = "demo-app-${var.environment}-api"

  managed {
    domains = ["api.demo.pump.example"]
  }
}

resource "google_compute_global_forwarding_rule" "api_https" {
  name                  = "demo-app-${var.environment}-api-https"
  ip_address            = google_compute_global_address.ingress.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.api.id
}
