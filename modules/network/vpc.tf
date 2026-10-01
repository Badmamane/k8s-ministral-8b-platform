module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway     = var.nat_gateway.enabled
  single_nat_gateway     = var.nat_gateway.enabled && !var.nat_gateway.per_az
  one_nat_gateway_per_az = var.nat_gateway.enabled && var.nat_gateway.per_az

  enable_dns_hostnames = var.dns.hostnames
  enable_dns_support   = var.dns.support

  map_public_ip_on_launch = var.map_public_ip_on_launch

  enable_flow_log                                 = var.flow_logs.enabled
  flow_log_destination_type                       = "cloud-watch-logs"
  create_flow_log_cloudwatch_log_group            = var.flow_logs.enabled
  create_flow_log_cloudwatch_iam_role             = var.flow_logs.enabled
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_logs.retention_days

  private_subnet_tags = local.private_subnet_tags
  public_subnet_tags  = local.public_subnet_tags

  tags = var.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.7"

  vpc_id = module.vpc.vpc_id

  endpoints = local.gateway_endpoints
  tags      = var.tags
}
