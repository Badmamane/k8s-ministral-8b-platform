data "aws_caller_identity" "current" {}

locals {
  name = "${var.project}-${var.env}"

  autoscaling_slr_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"

  efs_ingress_rules = {
    for cidr in var.private_subnet_cidrs :
    replace(cidr, "/[./]/", "-") => {
      description = "NFS from private subnet ${cidr}"
      from_port   = var.efs_port
      to_port     = var.efs_port
      ip_protocol = "tcp"
      cidr_ipv4   = cidr
    }
  }

  rds_ingress_rules = {
    for cidr in var.private_subnet_cidrs :
    replace(cidr, "/[./]/", "-") => {
      description = "MariaDB from private subnet ${cidr}"
      from_port   = var.rds_port
      to_port     = var.rds_port
      ip_protocol = "tcp"
      cidr_ipv4   = cidr
    }
  }

  ingress_rules = {
    for pair in setproduct(var.ingress_ports, var.ingress_allowed_cidrs) :
    "${pair[0]}-${pair[1]}" => {
      description = "Ingress on ${pair[0]} from ${pair[1]}"
      from_port   = pair[0]
      to_port     = pair[0]
      ip_protocol = "tcp"
      cidr_ipv4   = pair[1]
    }
  }
}
