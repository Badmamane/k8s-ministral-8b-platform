include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules//storage"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000000", "subnet-11111111111111111"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "security" {
  config_path = "../security"

  mock_outputs = {
    kms_key_arns = { storage = "arn:aws:kms:us-east-1:000000000000:key/mock" }
    security_group_ids = {
      efs = "sg-00000000000000000",
      rds = "sg-11111111111111111"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

inputs = {
  vpc_id                = dependency.network.outputs.vpc_id
  private_subnet_ids    = dependency.network.outputs.private_subnet_ids
  efs_security_group_id = dependency.security.outputs.security_group_ids["efs"]
  rds_security_group_id = dependency.security.outputs.security_group_ids["rds"]
  storage_kms_key_arn   = dependency.security.outputs.kms_key_arns["storage"]
  rds                   = local.env.rds
  buckets               = local.env.buckets
  efs                   = local.env.efs
  ecr                   = local.env.ecr
  ecr_repositories      = local.env.ecr_repositories
}
