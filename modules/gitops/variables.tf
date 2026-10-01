variable "cluster_name" {
  type = string
}

variable "bucket_arns" {
  description = "Bucket ARNs by logical name, from the storage unit"
  type        = map(string)
}

variable "argocd" {
  description = "Argo CD installation settings"
  type = object({
    chart_version      = string
    apps_chart_version = string
    namespace          = string
    node_selector      = map(string)
  })
}

variable "gitops" {
  description = "Repository Argo CD syncs the app-of-apps from"
  type = object({
    repo_url               = string
    revision               = string
    path                   = string
    workloads_path         = string
    deploy_key_secret_name = optional(string)
  })
}

variable "rds_master_secret_arn" {
  description = "Secrets Manager ARN of the RDS-managed master password, read by External Secrets"
  type        = string
}

variable "storage_kms_key_arn" {
  description = "KMS key encrypting the RDS-managed secret and the buckets"
  type        = string
}

variable "cluster_values" {
  description = "Environment values published as annotations on the Argo CD in-cluster Secret, read by ApplicationSets"
  type        = map(string)
}
