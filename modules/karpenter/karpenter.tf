module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.25"

  cluster_name = var.cluster_name

  namespace                       = var.karpenter.namespace
  service_account                 = "karpenter"
  create_pod_identity_association = true

  iam_role_name              = "${local.name}-karpenter-controller"
  iam_role_use_name_prefix   = false
  iam_policy_name            = "${local.name}-karpenter-controller"
  iam_policy_use_name_prefix = false

  iam_role_policies = {
    extra = module.controller_extra_policy.arn
  }

  node_iam_role_name            = "${local.name}-karpenter-node"
  node_iam_role_use_name_prefix = false
  create_access_entry           = true
  enable_inline_policy          = true

  queue_name              = "${local.name}-karpenter"
  enable_spot_termination = true

  tags = var.tags
}
