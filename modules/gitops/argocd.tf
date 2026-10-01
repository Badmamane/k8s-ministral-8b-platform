resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = var.argocd.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd.chart_version

  create_namespace = true
  wait             = true

  values = [yamlencode({
    global = {
      nodeSelector = var.argocd.node_selector
    }
    configs = {
      params = {
        "server.insecure" = true
      }
    }
    dex = {
      enabled = false
    }
    notifications = {
      enabled = false
    }
  })]
}

resource "helm_release" "root_app" {
  name       = "root"
  namespace  = var.argocd.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd.apps_chart_version

  wait = true

  values = [yamlencode({
    applications = {
      root = {
        namespace  = var.argocd.namespace
        project    = "default"
        finalizers = ["resources-finalizer.argocd.argoproj.io"]
        source = {
          repoURL        = var.gitops.repo_url
          targetRevision = var.gitops.revision
          path           = var.gitops.path
          directory = {
            recurse = true
            exclude = "workloads/**"
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = var.argocd.namespace
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
          retry = {
            limit = 5
            backoff = {
              duration    = "30s"
              factor      = 2
              maxDuration = "5m"
            }
          }
          syncOptions = ["CreateNamespace=true"]
        }
      }
    }
  })]

  depends_on = [helm_release.argocd, module.pod_identity, kubernetes_secret_v1.in_cluster]
}

# ------ Workloads own load balancers that the platform's controller must delete;
# ------ this release depends on the platform root so Terraform removes it first,
# ------ and Helm waits for the Application (and its cascade) to be gone.
resource "helm_release" "workloads_app" {
  name       = "workloads"
  namespace  = var.argocd.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd.apps_chart_version

  wait    = true
  timeout = 900

  values = [yamlencode({
    applications = {
      workloads = {
        namespace  = var.argocd.namespace
        project    = "default"
        finalizers = ["resources-finalizer.argocd.argoproj.io"]
        source = {
          repoURL        = var.gitops.repo_url
          targetRevision = var.gitops.revision
          path           = var.gitops.workloads_path
          directory = {
            recurse = true
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = var.argocd.namespace
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
          retry = {
            limit = 5
            backoff = {
              duration    = "30s"
              factor      = 2
              maxDuration = "5m"
            }
          }
          syncOptions = ["CreateNamespace=true"]
        }
      }
    }
  })]

  depends_on = [helm_release.root_app]
}
