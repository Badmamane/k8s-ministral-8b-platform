include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env          = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  runner_cidrs = compact([get_env("RUNNER_CIDR", "")])
}

terraform {
  source = "${get_repo_root()}/modules//eks"
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
    kms_key_arns = {
      eks     = "arn:aws:kms:us-east-1:000000000000:key/mock-eks"
      storage = "arn:aws:kms:us-east-1:000000000000:key/mock-storage"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "storage" {
  config_path  = "../storage"
  skip_outputs = true
}

inputs = {
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids

  kubernetes_version = local.env.kubernetes_version
  cluster = merge(local.env.cluster, {
    endpoint_public_access_cidrs = concat(local.env.cluster.endpoint_public_access_cidrs, local.runner_cidrs)
  })
  cpu_node_group       = local.env.cpu_node_group
  addons               = local.env.addons
  admin_principal_arns = local.env.admin_principal_arns

  eks_kms_key_arn     = dependency.security.outputs.kms_key_arns["eks"]
  storage_kms_key_arn = dependency.security.outputs.kms_key_arns["storage"]
}
