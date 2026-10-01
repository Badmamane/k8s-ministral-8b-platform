include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules//network"
}

inputs = {
  vpc_cidr           = local.env.vpc_cidr
  availability_zones = local.env.availability_zones
  subnet_newbits     = local.env.subnet_newbits

  nat_gateway             = local.env.nat_gateway
  dns                     = local.env.dns
  map_public_ip_on_launch = local.env.map_public_ip_on_launch
  flow_logs               = local.env.flow_logs
  gateway_endpoints       = local.env.gateway_endpoints
  subnet_tags             = local.env.subnet_tags
}
