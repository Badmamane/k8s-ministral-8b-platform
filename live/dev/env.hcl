locals {
  env          = "dev"
  account_name = "dev-aws-account"
  region       = "us-east-1"

  vpc_cidr           = "10.42.0.0/16"
  availability_zones = 4
  subnet_newbits     = 4

  nat_gateway = {
    enabled = true
    per_az  = false
  }

  dns = {
    hostnames = true
    support   = true
  }

  map_public_ip_on_launch = false

  flow_logs = {
    enabled        = true
    retention_days = 7
  }

  gateway_endpoints = ["s3"]

  subnet_tags = {
    private = {}
    public  = {}
  }

  kms = {
    deletion_window_days = 7
    enable_key_rotation  = true
  }

  kms_keys = {
    eks = {
      description       = "EKS secrets envelope encryption"
      grant_autoscaling = false
    }
    storage = {
      description       = "S3 buckets, EFS and ECR at rest, node and CSI volumes"
      grant_autoscaling = true
    }
  }

  admin_cidrs = compact(split(",", get_env("ADMIN_CIDRS", "")))

  ingress_allowed_cidrs = local.admin_cidrs
  ingress_ports         = [443, 22]
  efs_port              = 2049

  destroy_wait_timeout_seconds = 600

  buckets = {
    models = {
      versioning                         = false
      noncurrent_version_expiration_days = 1
      force_destroy                      = true
    }
    checkpoints = {
      versioning                         = true
      noncurrent_version_expiration_days = 14
      force_destroy                      = true
    }
    loki = {
      versioning                         = false
      noncurrent_version_expiration_days = 1
      force_destroy                      = true
    }
    tempo = {
      versioning                         = false
      noncurrent_version_expiration_days = 1
      force_destroy                      = true
    }
  }

  rds_port = 3306

  rds = {
    engine_version           = "12.3"
    family                   = "mariadb12.3"
    major_engine_version     = "12.3"
    instance_class           = "db.t4g.micro"
    allocated_storage_gb     = 20
    max_allocated_storage_gb = 50
    az_count                 = 1
    db_name                  = "slurm_acct_db"
    username                 = "slurm"
    port                     = 3306
    backup_retention_days    = 1
    deletion_protection      = false
    skip_final_snapshot      = true
  }

  efs = {
    performance_mode = "generalPurpose"
    throughput_mode  = "elastic"
    transition_to_ia = "AFTER_7_DAYS"
  }

  ecr = {
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    keep_last_images     = 10
    force_delete         = true
  }

  ecr_repositories = ["slurmd", "vllm"]

  kubernetes_version = "1.35"

  cluster = {
    endpoint_public_access       = true
    endpoint_public_access_cidrs = local.admin_cidrs
    enabled_log_types            = ["api", "audit", "authenticator"]
    log_retention_days           = 7
    upgrade_support_type         = "STANDARD"
  }

  cpu_node_group = {
    instance_types = ["m7i-flex.xlarge"]
    capacity_type  = "ON_DEMAND"
    ami_type       = "AL2023_x86_64_STANDARD"
    min_size       = 1
    desired_size   = 1
    max_size       = 2
    disk_size_gb   = 50
  }

  addons = {
    vpc-cni = {
      before_compute = true
    }
    coredns = {
      before_compute = false
    }
    kube-proxy = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    metrics-server = {
      before_compute = false
    }
  }

  # ------ Replace 123456789012 with the account ID and the user with the human admin.
  # ------ The gha-lifecycle role is created by the bootstrap repository.
  admin_principal_arns = [
    "arn:aws:iam::123456789012:user/platform-admin",
    "arn:aws:iam::123456789012:role/k8s-ministral-8b-dev-gha-lifecycle",
  ]

  karpenter = {
    chart_version = "1.14.1"
    namespace     = "karpenter"
    replicas      = 1
    node_selector = {
      workload = "platform"
    }
  }

  gpu_nodepool = {
    instance_families = ["g6", "g5"]
    instance_sizes    = ["xlarge", "2xlarge"]
    capacity_types    = ["spot", "on-demand"]
    gpu_limit         = 2
    ami_alias         = "al2023@latest"
    disk_size_gb      = 100
    expire_after      = "720h"
    consolidate_after = "60s"
  }

  argocd = {
    chart_version      = "10.8.4"
    apps_chart_version = "2.0.5"
    namespace          = "argocd"
    node_selector = {
      workload = "platform"
    }
  }

  gitops = {
    repo_url       = "https://github.com/Badmamane/k8s-ministral-8b-platform.git"
    revision       = "master"
    path           = "gitops/apps"
    workloads_path = "gitops/apps/workloads"
    # ------ Public repository: Argo CD clones over HTTPS. For a private fork, store a
    # ------ read-only deploy key in Secrets Manager and name it here.
    deploy_key_secret_name = null
  }
}
