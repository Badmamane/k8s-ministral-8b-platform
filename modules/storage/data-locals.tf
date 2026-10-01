data "aws_caller_identity" "current" {}

locals {
  name       = "${var.project}-${var.env}"
  account_id = data.aws_caller_identity.current.account_id

  mount_targets = {
    for i, subnet_id in var.private_subnet_ids :
    "az${i}" => {
      subnet_id       = subnet_id
      security_groups = [var.efs_security_group_id]
    }
  }

  ecr_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last ${var.ecr.keep_last_images} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr.keep_last_images
      }
      action = {
        type = "expire"
      }
    }]
  })
}
