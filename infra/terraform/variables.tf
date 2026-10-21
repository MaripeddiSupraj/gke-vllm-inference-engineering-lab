variable "project_id" {
  description = "Existing dedicated GCP project ID. Never commit billing or credential information."
  type        = string
}
variable "region" {
  description = "Region for the lab. Confirm GPU quota before provisioning."
  type        = string
  default     = "us-central1"
}
variable "zone" {
  description = "Zone with T4 availability; verify before deployment."
  type        = string
  default     = "us-central1-a"
}
variable "cluster_name" {
  type    = string
  default = "gke-vllm-lab"
}
variable "gpu_node_count" {
  description = "ZERO by default. Set to 1 ONLY after explicit approval, verified budget safeguards and GPU quota."
  type        = number
  default     = 0
  validation {
    condition     = contains([0, 1], var.gpu_node_count)
    error_message = "Only 0 or 1 GPU node is allowed in this educational lab."
  }
}
variable "acknowledge_paid_infrastructure" {
  description = "Explicit acknowledgment for creating ANY billable cluster/CPU infrastructure."
  type        = bool
  default     = false
}
variable "acknowledge_gpu_cost" {
  description = "Additional acknowledgment for enabling the GPU node."
  type        = bool
  default     = false
}
