module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.2"

  for_each = toset(var.ecr_repositories)

  repository_name = "${local.name}/${each.key}"

  repository_type                 = "private"
  repository_image_tag_mutability = var.ecr.image_tag_mutability
  repository_image_scan_on_push   = var.ecr.scan_on_push
  repository_force_delete         = var.ecr.force_delete

  repository_encryption_type = "KMS"
  repository_kms_key         = var.storage_kms_key_arn

  create_lifecycle_policy     = true
  repository_lifecycle_policy = local.ecr_lifecycle_policy
}
