data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = "${var.project}-${var.env}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.availability_zones)

  # ------ Private subnets fill the lower half of the block space, public subnets the
  # ------ upper half, so growing availability_zones only adds subnets.
  private_subnets = [for i in range(var.availability_zones) : cidrsubnet(var.vpc_cidr, var.subnet_newbits, i)]
  public_subnets  = [for i in range(var.availability_zones) : cidrsubnet(var.vpc_cidr, var.subnet_newbits, i + pow(2, var.subnet_newbits - 1))]

  # ------ Contract with the Load Balancer Controller and Karpenter subnet discovery.
  private_subnet_tags = merge(
    {
      "kubernetes.io/role/internal-elb" = "1"
      "karpenter.sh/discovery"          = local.name
    },
    var.subnet_tags.private,
  )

  public_subnet_tags = merge(
    {
      "kubernetes.io/role/elb" = "1"
    },
    var.subnet_tags.public,
  )

  gateway_endpoints = {
    for service in var.gateway_endpoints : service => {
      service         = service
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${local.name}-${service}"
      }
    }
  }
}
