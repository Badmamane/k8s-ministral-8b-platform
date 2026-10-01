output "kms_key_arns" {
  description = "Map of KMS key ARNs by purpose"
  value       = { for k, m in module.kms : k => m.key_arn }
}

output "security_group_ids" {
  description = "Map of security group ids by purpose: efs, ingress"
  value = {
    efs     = module.efs_sg.id
    ingress = module.ingress_sg.id
    rds     = module.rds_sg.id
  }
}
