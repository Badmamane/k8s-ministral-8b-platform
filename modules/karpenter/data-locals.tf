data "aws_caller_identity" "current" {}

locals {
  name       = "${var.project}-${var.env}"
  account_id = data.aws_caller_identity.current.account_id
  node_tags  = merge(var.tags, { ManagedBy = "karpenter" })
}
