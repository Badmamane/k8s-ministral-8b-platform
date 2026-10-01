locals {
  project    = "k8s-ministral-8b"
  account_id = get_aws_account_id()

  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  env        = local.env_config.env
  region     = local.env_config.region

  tags = {
    Project     = local.project
    Environment = local.env
    Account     = local.env_config.account_name
  }
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket       = "${local.project}-${local.env}-tfstate-${local.account_id}"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    kms_key_id   = "alias/${local.project}-${local.env}-tfstate"
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    provider "aws" {
      region = "${local.region}"

      default_tags {
        tags = {
          Project     = "${local.project}"
          Environment = "${local.env}"
          Account     = "${local.env_config.account_name}"
          ManagedBy   = "terragrunt"
          Unit        = "${path_relative_to_include()}"
        }
      }
    }
  EOF
}

inputs = {
  project = local.project
  env     = local.env
  region  = local.region
  tags    = local.tags
}
