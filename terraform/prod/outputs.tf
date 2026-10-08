output "network_id" {
  value = google_compute_network.main.id
}

output "ingress_ip" {
  value = google_compute_global_address.ingress.address
}

output "sql_primary_connection_name" {
  value = google_sql_database_instance.primary.connection_name
}

# Surfaced so a reviewer can see commitment sizing next to the plan diff.
output "committed_vcpu_by_family" {
  value = {
    GENERAL_PURPOSE_N2  = 24
    GENERAL_PURPOSE_N2D = 24
  }
}

output "external_commitments" {
  description = "Commitments covering this stack that Terraform does not manage."
  value       = local.external_commitments
}
