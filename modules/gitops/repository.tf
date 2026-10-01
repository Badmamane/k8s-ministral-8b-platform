resource "kubernetes_secret_v1" "repo" {
  count = var.gitops.deploy_key_secret_name != null ? 1 : 0

  metadata {
    name      = "repo-${var.project}"
    namespace = var.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.gitops.repo_url
    sshPrivateKey = data.aws_secretsmanager_secret_version.deploy_key[0].secret_string
  }

  lifecycle {
    precondition {
      condition     = data.aws_secretsmanager_secret_version.deploy_key[0].secret_string != "PLACEHOLDER"
      error_message = "Secret ${var.gitops.deploy_key_secret_name} still holds the placeholder value; set the deploy key first."
    }
  }

  depends_on = [helm_release.argocd]
}
