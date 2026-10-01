variable "vpc_id" {
  description = "VPC the security groups belong to"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR, used as source for intra-VPC rules"
  type        = string
}

variable "kms" {
  description = "KMS key settings shared by every key of this environment"
  type = object({
    deletion_window_days = number
    enable_key_rotation  = bool
  })
}

variable "ingress_allowed_cidrs" {
  description = "Source CIDRs allowed to reach the public ingress (NLB) on the listener ports"
  type        = list(string)
}

variable "ingress_ports" {
  description = "Listener ports exposed by the public ingress"
  type        = list(number)
}

variable "efs_port" {
  description = "NFS port for EFS mount targets"
  type        = number
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs allowed to reach EFS mount targets"
  type        = list(string)
}

variable "kms_keys" {
  description = "Keys to create, by purpose; the map key becomes the alias suffix and the output key"
  type = map(object({
    description       = string
    grant_autoscaling = bool
  }))
}

variable "rds_port" {
  description = "Database port for the RDS security group"
  type        = number
}
