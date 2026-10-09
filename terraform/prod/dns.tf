resource "google_dns_managed_zone" "public" {
  name        = "demo-app-${var.environment}"
  dns_name    = "demo.pump.example."
  description = "Public DNS for the demo application"
  visibility  = "public"

  labels = local.common_labels
}

resource "google_dns_record_set" "api" {
  name         = "api.${google_dns_managed_zone.public.dns_name}"
  managed_zone = google_dns_managed_zone.public.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.ingress.address]
}

resource "google_dns_record_set" "app_cname" {
  name         = "app.${google_dns_managed_zone.public.dns_name}"
  managed_zone = google_dns_managed_zone.public.name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [google_dns_record_set.api.name]
}
