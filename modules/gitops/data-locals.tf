data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_kms_alias" "secrets" {
  name = "alias/${local.name}-secrets"
}

data "aws_secretsmanager_secret_version" "deploy_key" {
  count = var.gitops.deploy_key_secret_name != null ? 1 : 0

  secret_id = var.gitops.deploy_key_secret_name
}

locals {
  name       = "${var.project}-${var.env}"
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  secrets_prefix_arn = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${local.name}/*"

  # ------ Pod Identity roles for Argo CD-managed apps that talk to AWS.
  # ------ Key = role suffix; namespace/service_account must match the chart values.
  pod_identities = {
    aws-load-balancer-controller = {
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
      lb_controller   = true
    }
    external-secrets = {
      namespace        = "external-secrets"
      service_account  = "external-secrets"
      external_secrets = true
    }
    loki = {
      namespace       = "observability"
      service_account = "loki"
      bucket          = "loki"
    }
    tempo = {
      namespace       = "observability"
      service_account = "tempo"
      bucket          = "tempo"
    }
  }
}
