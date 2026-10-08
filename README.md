# demo-app-service

Test repository for IaC cost estimates. The Terraform here is not meant to be
applied — it exists to produce realistic, repeatable cost diffs on pull requests,
including a stack whose spend is partly covered by Google committed use
discounts.

## Layout

| Path | Purpose |
| --- | --- |
| `terraform/prod` | Main stack. Compute, GKE, Cloud SQL, Redis, storage, plus CUDs that cover part of it. |
| `terraform/staging` | Smaller control stack with no commitments at all. |
| `infracost.yml` | Declares both stacks as Infracost projects. |
| `infracost-usage.yml` | Usage estimates for resources Infracost cannot price from HCL alone. |
| `.github/workflows/iac-cost-estimate.yml` | Runs base and proposed breakdowns and submits the pair. |

The two stacks are separate source paths, so they register as two independent
estimate targets and each gets its own scoped ingestion credential.

## Commitment coverage

Google resource-based CUDs are regional and machine-family scoped. They apply to
on-demand usage of the same family in the same region, are billed whether or not
matching usage exists, and are never consumed by Spot or Autopilot workloads.
`terraform/prod/commitments.tf` is sized so coverage is known up front:

| Commitment | Term | Covers | Covered usage |
| --- | --- | --- | --- |
| `n2_api` (24 vCPU / 96 GB, N2) | 1 year | `google_compute_instance.api` | Full — 3 × `n2-standard-8` is exactly 24 vCPU / 96 GB |
| `n2d_platform` (24 vCPU / 96 GB, N2D) | 3 years | `google_container_node_pool.platform` | Half — the pool is 6 × `n2d-standard-8`, or 48 vCPU / 192 GB |

Deliberately left uncovered: the `n2-standard-4` workers, the `batch-spot` node
pool (Spot never stacks with a CUD), and everything non-compute.

`google_compute_reservation.api_headroom` is included as a contrast case. It is
billed like a running instance and consumed by matching VMs, but it is not a
discount.

Cloud SQL is covered by a **spend-based** CUD of $1,200/month, which Google only
sells through the Billing console and does not expose as a Terraform resource.
It is recorded as metadata in `terraform/prod/data.tf` and surfaced through the
`external_commitments` output. This is the realistic and most interesting case:
a commitment that genuinely covers the stack but is invisible to Terraform, so
an IaC estimate cannot see it without reconciling against billing data.

## Scenarios worth opening PRs for

- **Net-new uncovered spend.** Raise `worker_node_count`. The delta is entirely
  on-demand because no N2 commitment headroom is left.
- **Spend that lands inside existing coverage.** Shrink `api_node_count` to 2 and
  add a third worker. Compute totals barely move, but a quarter of the N2
  commitment becomes stranded — an estimate based on list price will miss this.
- **Family change that strands a commitment.** Switch the API fleet from
  `n2-standard-8` to `c3-standard-8`. List-price delta looks small; real cost
  rises because the N2 commitment keeps billing with nothing to cover.
- **Region change.** Flip `var.region`. Both commitments strand completely.
- **Unsupported coverage.** Delete `infracost-usage.yml` and re-run. Usage-driven
  resources such as Cloud Run and Cloud NAT lose their price, which should
  classify the run as `unsupported` rather than `estimated`.

## Running a breakdown locally

```bash
infracost auth login   # v2 requires an API key for pricing lookups
infracost breakdown --path terraform/prod --usage-file infracost-usage.yml
```

To diff a branch the way CI does:

```bash
infracost breakdown --path terraform/prod --usage-file infracost-usage.yml \
  --format json --out-file /tmp/proposed.json
```

Infracost prices on-demand list rates. It does not model CUDs, sustained use
discounts, or spend-based commitments, so its totals for `terraform/prod` are
higher than the real bill by roughly the covered portion. That gap is the point
of this repo.

## CI wiring

`.github/workflows/iac-cost-estimate.yml` checks out the base SHA, runs a
breakdown, checks out the head SHA, runs a second breakdown, and submits both as
one pair per stack. Required configuration:

| Name | Kind | Purpose |
| --- | --- | --- |
| `INFRACOST_API_KEY` | secret | Infracost pricing API |
| `PUMP_IAC_TOKEN` | secret | Target-scoped `piac_` bearer token |
| `PUMP_IAC_TARGET_ID_PROD` | secret | Registered target for `terraform/prod` |
| `PUMP_IAC_TARGET_ID_STAGING` | secret | Registered target for `terraform/staging` |
| `PUMP_API_BASE_URL` | variable | API origin |

The token resolves company and target server-side; nothing in the request body
selects a tenant. A new pair returns 201 and an identical replay returns 200, so
re-running the workflow on an unchanged commit is safe. Resubmitting different
content for the same base/proposed commit pair is a conflict by design.

To exercise the HCP Terraform run-task path instead, uncomment the `cloud` block
in `terraform/prod/versions.tf` and point the workspace at a VCS-connected
Terraform Cloud workspace with cost estimation enabled.
