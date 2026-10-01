variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "kubernetes_version" {
  type = string
}

variable "cluster" {
  description = "Control plane settings"
  type = object({
    endpoint_public_access       = bool
    endpoint_public_access_cidrs = list(string)
    enabled_log_types            = list(string)
    log_retention_days           = number
    upgrade_support_type         = string
  })

  validation {
    condition     = !var.cluster.endpoint_public_access || length(var.cluster.endpoint_public_access_cidrs) > 0
    error_message = "cluster.endpoint_public_access_cidrs is empty while the public endpoint is enabled; AWS would treat this as 0.0.0.0/0. Set ADMIN_CIDRS (mise) or disable endpoint_public_access."
  }

  validation {
    condition     = !contains(var.cluster.endpoint_public_access_cidrs, "0.0.0.0/0")
    error_message = "cluster.endpoint_public_access_cidrs must not contain 0.0.0.0/0; restrict the API endpoint to admin and runner CIDRs."
  }
}

variable "cpu_node_group" {
  description = "Always-on CPU managed node group"
  type = object({
    instance_types = list(string)
    capacity_type  = string
    ami_type       = string
    min_size       = number
    desired_size   = number
    max_size       = number
    disk_size_gb   = number
  })
}

variable "addons" {
  description = "EKS add-ons to install; empty map value means defaults"
  type = map(object({
    before_compute = bool
  }))
}

variable "eks_kms_key_arn" {
  description = "KMS key for Kubernetes secrets envelope encryption"
  type        = string
}

variable "storage_kms_key_arn" {
  description = "KMS key the EBS CSI driver may use for encrypted volumes"
  type        = string
}

variable "admin_principal_arns" {
  description = "IAM principals granted cluster-admin through access entries, besides the Terraform caller"
  type        = list(string)
}
