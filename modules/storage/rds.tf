module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = "${local.name}-slurmdbd"

  engine               = "mariadb"
  engine_version       = var.rds.engine_version
  family               = var.rds.family
  major_engine_version = var.rds.major_engine_version
  instance_class       = var.rds.instance_class

  allocated_storage     = var.rds.allocated_storage_gb
  max_allocated_storage = var.rds.max_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.storage_kms_key_arn

  db_name  = var.rds.db_name
  username = var.rds.username
  port     = var.rds.port

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.storage_kms_key_arn

  multi_az = var.rds.az_count > 1

  create_db_subnet_group          = true
  db_subnet_group_name            = "${local.name}-slurmdbd"
  db_subnet_group_use_name_prefix = false
  subnet_ids                      = var.private_subnet_ids
  vpc_security_group_ids          = [var.rds_security_group_id]

  create_db_option_group          = false
  parameter_group_use_name_prefix = false

  backup_retention_period = var.rds.backup_retention_days
  deletion_protection     = var.rds.deletion_protection
  skip_final_snapshot     = var.rds.skip_final_snapshot
  apply_immediately       = true

  tags = var.tags
}
