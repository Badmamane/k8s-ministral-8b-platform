variable "private_subnet_ids" {
  description = "Subnets receiving EFS mount targets"
  type        = list(string)
}

variable "efs_security_group_id" {
  type = string
}

variable "storage_kms_key_arn" {
  description = "KMS key encrypting buckets, EFS and ECR"
  type        = string
}

variable "buckets" {
  description = "Buckets by logical name; each becomes <project>-<env>-<name>-<account_id>"
  type = map(object({
    versioning                         = bool
    noncurrent_version_expiration_days = number
    force_destroy                      = bool
  }))
}

variable "efs" {
  description = "Shared filesystem settings"
  type = object({
    performance_mode = string
    throughput_mode  = string
    transition_to_ia = string
  })
}

variable "ecr" {
  description = "Settings shared by every container image repository"
  type = object({
    image_tag_mutability = string
    scan_on_push         = bool
    keep_last_images     = number
    force_delete         = bool
  })
}

variable "ecr_repositories" {
  description = "Container image repositories to create"
  type        = list(string)
}

variable "rds_security_group_id" {
  type = string
}

variable "rds" {
  description = "RDS for MariaDB instance used by slurmdbd"
  type = object({
    engine_version           = string
    family                   = string
    major_engine_version     = string
    instance_class           = string
    allocated_storage_gb     = number
    max_allocated_storage_gb = number
    az_count                 = number
    db_name                  = string
    username                 = string
    port                     = number
    backup_retention_days    = number
    deletion_protection      = bool
    skip_final_snapshot      = bool
  })

  validation {
    condition     = contains([1, 2], var.rds.az_count)
    error_message = "rds.az_count must be 1 (single-AZ) or 2 (Multi-AZ standby)."
  }
}
