resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = var.karpenter.namespace
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter.chart_version

  create_namespace = true
  wait             = true

  values = [yamlencode({
    replicas     = var.karpenter.replicas
    nodeSelector = var.karpenter.node_selector
    serviceAccount = {
      name = module.karpenter.service_account
    }
    settings = {
      clusterName       = var.cluster_name
      interruptionQueue = module.karpenter.queue_name
    }
  })]

  depends_on = [module.karpenter]
}

resource "helm_release" "gpu_nodepool" {
  name      = "gpu-nodepool"
  namespace = var.karpenter.namespace
  chart     = "${path.module}/chart"

  wait = true

  values = [yamlencode({
    clusterName      = var.cluster_name
    nodeRole         = module.karpenter.node_iam_role_name
    kmsKeyArn        = var.storage_kms_key_arn
    tags             = local.node_tags
    amiAlias         = var.gpu_nodepool.ami_alias
    diskSizeGb       = var.gpu_nodepool.disk_size_gb
    families         = var.gpu_nodepool.instance_families
    sizes            = var.gpu_nodepool.instance_sizes
    capacityTypes    = var.gpu_nodepool.capacity_types
    gpuLimit         = var.gpu_nodepool.gpu_limit
    expireAfter      = var.gpu_nodepool.expire_after
    consolidateAfter = var.gpu_nodepool.consolidate_after
  })]

  depends_on = [helm_release.karpenter]
}
