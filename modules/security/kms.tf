module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  for_each = var.kms_keys

  description             = each.value.description
  aliases                 = ["${local.name}-${each.key}"]
  deletion_window_in_days = var.kms.deletion_window_days
  enable_key_rotation     = var.kms.enable_key_rotation

  key_users         = each.value.grant_autoscaling ? [local.autoscaling_slr_arn] : []
  key_service_users = each.value.grant_autoscaling ? [local.autoscaling_slr_arn] : []
}
