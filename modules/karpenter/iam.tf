data "aws_iam_policy_document" "controller_extra" {
  statement {
    sid = "UseStorageKmsKeyForNodeVolumes"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = [var.storage_kms_key_arn]
  }

  statement {
    sid    = "DenyLaunchWithoutProjectTag"
    effect = "Deny"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
    ]
    resources = ["arn:aws:ec2:*:${local.account_id}:instance/*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project]
    }
  }
}

module "controller_extra_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "${local.name}-karpenter-controller-extra"
  description = "Storage KMS key usage and tag enforcement for Karpenter-launched instances"
  policy      = data.aws_iam_policy_document.controller_extra.json
}
