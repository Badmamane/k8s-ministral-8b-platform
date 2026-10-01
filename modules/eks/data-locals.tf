locals {
  name = "${var.project}-${var.env}"

  addons = {
    for k, v in var.addons : k => {
      before_compute = v.before_compute
      most_recent    = true
    }
  }

  admin_access_entries = {
    for arn in var.admin_principal_arns : arn => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
