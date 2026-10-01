module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name               = "${local.name}-ebs-csi"
  use_name_prefix    = false
  policy_name_prefix = "${local.name}-"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [var.storage_kms_key_arn]
}

module "efs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name               = "${local.name}-efs-csi"
  use_name_prefix    = false
  policy_name_prefix = "${local.name}-"

  attach_aws_efs_csi_policy = true
}
