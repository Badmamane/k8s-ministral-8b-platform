include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules//gitops"
}

generate "helm_provider" {
  path      = "provider_helm.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    provider "helm" {
      kubernetes = {
        host                   = "${dependency.eks.outputs.cluster_endpoint}"
        cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_ca_certificate}")
        exec = {
          api_version = "client.authentication.k8s.io/v1"
          command     = "aws"
          args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}", "--region", "${local.env.region}"]
        }
      }
    }
  EOF
}

generate "kubernetes_provider" {
  path      = "provider_kubernetes.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    provider "kubernetes" {
      host                   = "${dependency.eks.outputs.cluster_endpoint}"
      cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_ca_certificate}")

      exec {
        api_version = "client.authentication.k8s.io/v1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}", "--region", "${local.env.region}"]
      }
    }
  EOF
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "https://mock.eks.amazonaws.com"
    cluster_ca_certificate = ""
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "karpenter" {
  config_path  = "../karpenter"
  skip_outputs = true
}

dependency "storage" {
  config_path = "../storage"

  mock_outputs = {
    bucket_arns = {
      loki  = "arn:aws:s3:::mock-loki"
      tempo = "arn:aws:s3:::mock-tempo"
    }
    bucket_ids = {
      loki        = "mock-loki"
      tempo       = "mock-tempo"
      models      = "mock-models"
      checkpoints = "mock-checkpoints"
    }
    rds_endpoint          = "mock.rds.amazonaws.com:3306"
    rds_master_secret_arn = "arn:aws:secretsmanager:us-east-1:000000000000:secret:rds!db-mock"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "security" {
  config_path = "../security"

  mock_outputs = {
    kms_key_arns       = { storage = "arn:aws:kms:us-east-1:000000000000:key/mock-storage" }
    security_group_ids = { ingress = "sg-00000000000000000" }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

inputs = {
  cluster_name          = dependency.eks.outputs.cluster_name
  bucket_arns           = dependency.storage.outputs.bucket_arns
  rds_master_secret_arn = dependency.storage.outputs.rds_master_secret_arn
  storage_kms_key_arn   = dependency.security.outputs.kms_key_arns["storage"]

  argocd = local.env.argocd
  gitops = local.env.gitops

  cluster_values = {
    cluster_name              = dependency.eks.outputs.cluster_name
    region                    = local.env.region
    account_id                = get_aws_account_id()
    vpc_id                    = dependency.network.outputs.vpc_id
    ingress_security_group_id = dependency.security.outputs.security_group_ids["ingress"]
    rds_host                  = split(":", dependency.storage.outputs.rds_endpoint)[0]
    rds_port                  = tostring(local.env.rds.port)
    rds_secret_arn            = dependency.storage.outputs.rds_master_secret_arn
    loki_bucket               = dependency.storage.outputs.bucket_ids["loki"]
    tempo_bucket              = dependency.storage.outputs.bucket_ids["tempo"]
    models_bucket             = dependency.storage.outputs.bucket_ids["models"]
    checkpoints_bucket        = dependency.storage.outputs.bucket_ids["checkpoints"]
    secrets_prefix            = "${include.root.locals.project}-${local.env.env}"
    storage_kms_key_arn       = dependency.security.outputs.kms_key_arns["storage"]
  }
}
