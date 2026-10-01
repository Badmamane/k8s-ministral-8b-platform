variable "cluster_name" {
  type = string
}

variable "storage_kms_key_arn" {
  description = "KMS key used for the root volumes of Karpenter-launched nodes"
  type        = string
}

variable "karpenter" {
  description = "Karpenter controller settings"
  type = object({
    chart_version = string
    namespace     = string
    replicas      = number
    node_selector = map(string)
  })
}

variable "gpu_nodepool" {
  description = "GPU NodePool and EC2NodeClass settings"
  type = object({
    instance_families = list(string)
    instance_sizes    = list(string)
    capacity_types    = list(string)
    gpu_limit         = number
    ami_alias         = string
    disk_size_gb      = number
    expire_after      = string
    consolidate_after = string
  })
}
