output "bucket_arns" {
  description = "Map of bucket ARNs by logical name"
  value       = { for k, m in module.buckets : k => m.s3_bucket_arn }
}

output "bucket_ids" {
  description = "Map of bucket names by logical name"
  value       = { for k, m in module.buckets : k => m.s3_bucket_id }
}

output "efs_id" {
  value = module.efs.id
}

output "efs_dns_name" {
  value = module.efs.dns_name
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs by name"
  value       = { for k, m in module.ecr : k => m.repository_url }
}

output "rds_endpoint" {
  description = "host:port of the slurmdbd database"
  value       = module.rds.db_instance_endpoint
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN of the RDS-managed master password"
  value       = module.rds.db_instance_master_user_secret_arn
}
