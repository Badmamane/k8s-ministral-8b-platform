module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 2.2"

  name = local.name

  encrypted   = true
  kms_key_arn = var.storage_kms_key_arn

  # ------ The module enables AWS Backup by default: daily recovery points that outlive
  # ------ every destroy (found by orphan-check). Nothing on this dev filesystem is
  # ------ worth a backup; a durable environment would set a retention here instead.
  enable_backup_policy = false

  performance_mode = var.efs.performance_mode
  throughput_mode  = var.efs.throughput_mode

  lifecycle_policy = {
    transition_to_ia = var.efs.transition_to_ia
  }

  create_security_group = false
  mount_targets         = local.mount_targets

  attach_policy            = true
  deny_nonsecure_transport = true
}
