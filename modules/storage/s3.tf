module "buckets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  for_each = var.buckets

  bucket        = "${local.name}-${each.key}-${local.account_id}"
  force_destroy = each.value.force_destroy

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true

  versioning = {
    enabled = each.value.versioning
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = var.storage_kms_key_arn
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = [{
    id      = "expire-noncurrent-versions"
    enabled = each.value.versioning
    filter  = {}
    noncurrent_version_expiration = {
      days = each.value.noncurrent_version_expiration_days
    }
  }]
}
