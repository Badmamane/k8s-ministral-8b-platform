# ------ Declaring the in-cluster as a cluster Secret lets the ApplicationSet
# ------ cluster generator see it and read the environment values from its
# ------ annotations. server=https://kubernetes.default.svc keeps Argo CD on
# ------ its own service account; no credentials are stored here.
resource "kubernetes_secret_v1" "in_cluster" {
  metadata {
    name      = "in-cluster"
    namespace = var.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      environment                      = var.env
    }
    annotations = var.cluster_values
  }

  data = {
    name   = "in-cluster"
    server = "https://kubernetes.default.svc"
  }

  depends_on = [helm_release.argocd]
}
