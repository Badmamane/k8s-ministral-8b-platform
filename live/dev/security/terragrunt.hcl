include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env          = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  runner_cidrs = compact([get_env("RUNNER_CIDR", "")])
}

terraform {
  source = "${get_repo_root()}/modules//security"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id               = "vpc-00000000000000000"
    vpc_cidr             = "10.0.0.0/16"
    private_subnet_cidrs = ["10.0.0.0/20", "10.0.16.0/20"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

inputs = {
  vpc_id                = dependency.network.outputs.vpc_id
  vpc_cidr              = dependency.network.outputs.vpc_cidr
  private_subnet_cidrs  = dependency.network.outputs.private_subnet_cidrs
  kms                   = local.env.kms
  kms_keys              = local.env.kms_keys
  ingress_allowed_cidrs = concat(local.env.ingress_allowed_cidrs, local.runner_cidrs)
  ingress_ports         = local.env.ingress_ports
  efs_port              = local.env.efs_port
  rds_port              = local.env.rds_port
}
