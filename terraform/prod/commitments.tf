# Committed use discounts.
#
# Google resource-based CUDs are regional and family-scoped: a commitment only
# applies to on-demand usage of the same machine family in the same region, and
# it is billed whether or not usage exists. Spot, Autopilot, and preemptible
# usage can never consume them.
#
# Sizing here is deliberate so the stack has a known coverage story:
#
#   n2_api       24 vCPU / 96 GB   covers google_compute_instance.api exactly
#                                  (3 x n2-standard-8). The n2-standard-4 workers
#                                  are left uncovered on purpose.
#   n2d_platform 24 vCPU / 96 GB   covers half of google_container_node_pool.platform
#                                  (6 x n2d-standard-8 == 48 vCPU / 192 GB).
#
# Scaling api_node_count or worker_node_count up in a PR produces net-new
# on-demand spend; scaling down produces stranded commitment spend. Both are
# useful diffs for a prospective-cost estimate to reason about.

resource "google_compute_region_commitment" "n2_api" {
  name     = "demo-app-${var.environment}-n2-1yr"
  region   = var.region
  plan     = "TWELVE_MONTH"
  type     = "GENERAL_PURPOSE_N2"
  category = "MACHINE"

  resources {
    type   = "VCPU"
    amount = "24"
  }

  resources {
    type   = "MEMORY"
    amount = "96"
  }
}

resource "google_compute_region_commitment" "n2d_platform" {
  name     = "demo-app-${var.environment}-n2d-3yr"
  region   = var.region
  plan     = "THIRTY_SIX_MONTH"
  type     = "GENERAL_PURPOSE_N2D"
  category = "MACHINE"

  resources {
    type   = "VCPU"
    amount = "24"
  }

  resources {
    type   = "MEMORY"
    amount = "96"
  }
}

# A capacity reservation is not a discount, but it is billed like running
# instances and is consumed by matching VMs. It is included so the stack has a
# resource whose cost is real but whose coverage semantics differ from a CUD.
resource "google_compute_reservation" "api_headroom" {
  name = "demo-app-${var.environment}-api-headroom"
  zone = var.zone

  specific_reservation {
    count = 1

    instance_properties {
      machine_type = "n2-standard-8"
    }
  }

  specific_reservation_required = false
}
