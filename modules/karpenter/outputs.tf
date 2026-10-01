output "gpu_nodepool_name" {
  value = "gpu"
}

output "node_iam_role_arn" {
  value = module.karpenter.node_iam_role_arn
}
