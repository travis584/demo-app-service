variable "project_id" {
  description = "GCP project that owns the prod stack."
  type        = string
  default     = "pump-demo-prod"
}

variable "region" {
  description = "Primary region. Commitments are regional, so changing this strands them."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Primary zone for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment label echoed into resource labels."
  type        = string
  default     = "prod"
}

variable "api_node_count" {
  description = "Number of n2-standard-8 API nodes. Commitment covers 3."
  type        = number
  default     = 3
}

variable "worker_node_count" {
  description = "Number of n2-standard-4 async worker nodes. Not commitment-covered."
  type        = number
  default     = 2
}
