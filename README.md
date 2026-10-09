# demo-app-service

Test repository for HCP Terraform prospective cost estimates. The Terraform here
is not meant to be applied — it exists to produce realistic, repeatable cost
diffs on pull requests via speculative plans, including a stack whose spend is
partly covered by Google committed use discounts.

## Layout

| Path | Purpose |
| --- | --- |
| `terraform/prod` | Main stack for TFC workspace testing. Compute, GKE, Cloud SQL, Redis, storage, plus CUDs that cover part of it. |
| `terraform/staging` | Smaller stack with no commitments (optional second workspace). |

## Commitment coverage

Google resource-based CUDs are regional and machine-family scoped. They apply to
on-demand usage of the same family in the same region, are billed whether or not
matching usage exists, and are never consumed by Spot or Autopilot workloads.
`terraform/prod/commitments.tf` is sized so coverage is known up front:

| Commitment | Term | Covers | Covered usage |
| --- | --- | --- | --- |
| `n2_api` (24 vCPU / 96 GB, N2) | 1 year | `google_compute_instance.api` | Sized for 3 × `n2-standard-8` (24 vCPU / 96 GB) |
| `n2d_platform` (24 vCPU / 96 GB, N2D) | 3 years | `google_container_node_pool.platform` | Half of 6 × `n2d-standard-8` at baseline sizing |

Deliberately left uncovered: workers, the Spot batch pool, and non-compute services.

Cloud SQL is covered by a **spend-based** CUD of $1,200/month recorded as metadata
in `terraform/prod/data.tf` (`external_commitments` output). It is not a Terraform
resource — useful when reconciling TFC list-price estimates against real billing.

## Scenarios worth opening PRs for

- **Net-new uncovered spend.** Raise `worker_node_count`.
- **Spend inside vs outside coverage.** Change `api_node_count` relative to the N2 commitment (3 nodes at baseline).
- **Family change.** Switch API machines from `n2-standard-8` to another family.
- **Region change.** Flip `var.region` to strand regional commitments.

## HCP Terraform setup

1. Connect this repo to a VCS-driven workspace with working directory `terraform/prod`.
2. Enable cost estimation and attach your post-plan run task to Pump.
3. Optionally uncomment the `cloud` block in `terraform/prod/versions.tf` and set organization/workspace for local `terraform init`.

Opening a pull request triggers a speculative plan; the post-plan run task delivers the native cost estimate to Pump and the GitHub Check when GitHub delivery is configured on the target.
