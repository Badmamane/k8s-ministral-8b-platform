data "aws_iam_policy_document" "bucket_rw" {
  for_each = { for k, v in local.pod_identities : k => v if lookup(v, "bucket", null) != null }

  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arns[each.value.bucket]]
  }

  statement {
    sid = "ReadWriteObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${var.bucket_arns[each.value.bucket]}/*"]
  }

  statement {
    sid = "UseStorageKmsKey"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [var.storage_kms_key_arn]
  }
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  for_each = local.pod_identities

  name               = "${local.name}-${each.key}"
  use_name_prefix    = false
  policy_name_prefix = "${local.name}-"

  attach_aws_lb_controller_policy = lookup(each.value, "lb_controller", false)

  attach_external_secrets_policy        = lookup(each.value, "external_secrets", false)
  external_secrets_secrets_manager_arns = lookup(each.value, "external_secrets", false) ? [local.secrets_prefix_arn, var.rds_master_secret_arn] : []
  external_secrets_kms_key_arns         = lookup(each.value, "external_secrets", false) ? [data.aws_kms_alias.secrets.target_key_arn, var.storage_kms_key_arn] : []
  external_secrets_create_permission    = false

  attach_custom_policy    = lookup(each.value, "bucket", null) != null
  source_policy_documents = lookup(each.value, "bucket", null) != null ? [data.aws_iam_policy_document.bucket_rw[each.key].json] : []

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = each.value.namespace
      service_account = each.value.service_account
    }
  }

  tags = var.tags
}
