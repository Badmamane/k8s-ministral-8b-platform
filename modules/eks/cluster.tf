module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.25"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  endpoint_private_access      = true
  endpoint_public_access       = var.cluster.endpoint_public_access
  endpoint_public_access_cidrs = var.cluster.endpoint_public_access_cidrs

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = false
  access_entries                           = local.admin_access_entries

  enable_irsa = false

  create_kms_key = false
  encryption_config = {
    provider_key_arn = var.eks_kms_key_arn
    resources        = ["secrets"]
  }

  enabled_log_types                      = var.cluster.enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cluster.log_retention_days

  upgrade_policy = {
    support_type = var.cluster.upgrade_support_type
  }

  iam_role_name            = "${local.name}-cluster"
  iam_role_use_name_prefix = false

  addons = merge(local.addons, {
    aws-ebs-csi-driver = {
      most_recent = true
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
    aws-efs-csi-driver = {
      most_recent = true
      pod_identity_association = [{
        role_arn        = module.efs_csi_pod_identity.iam_role_arn
        service_account = "efs-csi-controller-sa"
      }]
    }
  })

  eks_managed_node_groups = {
    cpu = {
      name            = "${local.name}-cpu"
      use_name_prefix = false

      iam_role_name            = "${local.name}-cpu-node"
      iam_role_use_name_prefix = false

      instance_types = var.cpu_node_group.instance_types
      capacity_type  = var.cpu_node_group.capacity_type
      ami_type       = var.cpu_node_group.ami_type

      min_size     = var.cpu_node_group.min_size
      desired_size = var.cpu_node_group.desired_size
      max_size     = var.cpu_node_group.max_size

      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.cpu_node_group.disk_size_gb
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = var.storage_kms_key_arn
            delete_on_termination = true
          }
        }
      }

      labels = {
        "workload" = "platform"
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }

  tags = merge(var.tags, { ManagedBy = "eks-managed-node-group" })
}
