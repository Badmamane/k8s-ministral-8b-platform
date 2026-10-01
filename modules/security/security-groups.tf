module "efs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name            = "${local.name}-efs"
  use_name_prefix = false
  description     = "EFS mount targets, NFS from private subnets"
  vpc_id          = var.vpc_id

  ingress_rules = local.efs_ingress_rules
}

module "ingress_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name            = "${local.name}-ingress"
  use_name_prefix = false
  description     = "Public ingress (NLB) listener ports"
  vpc_id          = var.vpc_id

  ingress_rules = local.ingress_rules

  egress_rules = {
    all = {
      description = "To the VPC"
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
    }
  }
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name            = "${local.name}-rds"
  use_name_prefix = false
  description     = "RDS for slurmdbd, MariaDB from private subnets"
  vpc_id          = var.vpc_id

  ingress_rules = local.rds_ingress_rules
}
