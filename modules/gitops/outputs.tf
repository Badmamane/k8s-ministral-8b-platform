output "argocd_namespace" {
  value = var.argocd.namespace
}

output "pod_identity_role_arns" {
  description = "IAM role ARNs by app, for reference"
  value       = { for k, m in module.pod_identity : k => m.iam_role_arn }
}
