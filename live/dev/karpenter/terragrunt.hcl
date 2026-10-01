include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules//karpenter"

  # ------ The VPC in the network unit cannot be deleted while Karpenter-launched
  # ------ instances exist; poll EC2 here, in the right graph position.
  after_hook "wait_for_karpenter_nodes" {
    commands     = ["destroy"]
    run_on_error = false
    execute = ["bash", "-c", <<-EOT
      set -euo pipefail
      cluster="${dependency.eks.outputs.cluster_name}"
      region="${local.env.region}"
      deadline=$((SECONDS + ${local.env.destroy_wait_timeout_seconds}))

      remaining() {
        aws ec2 describe-instances --region "$region" \
          --filters "Name=tag:karpenter.sh/nodepool,Values=*" \
                    "Name=tag:kubernetes.io/cluster/$cluster,Values=owned" \
                    "Name=instance-state-name,Values=pending,running,shutting-down,stopping" \
          --query 'Reservations[].Instances[].InstanceId' --output text
      }

      while [ -n "$(remaining)" ]; do
        [ "$SECONDS" -lt "$deadline" ] || { echo "timeout, instances left: $(remaining)"; exit 1; }
        echo "waiting for Karpenter instances to terminate ..."; sleep 15
      done
      echo "no Karpenter instances left"
    EOT
    ]
  }
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

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "https://mock.eks.amazonaws.com"
    cluster_ca_certificate = ""
    node_security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]

}

dependency "security" {
  config_path = "../security"

  mock_outputs = {
    kms_key_arns = { storage = "arn:aws:kms:us-east-1:000000000000:key/mock-storage" }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

inputs = {
  cluster_name        = dependency.eks.outputs.cluster_name
  storage_kms_key_arn = dependency.security.outputs.kms_key_arns["storage"]

  karpenter    = local.env.karpenter
  gpu_nodepool = local.env.gpu_nodepool
}
