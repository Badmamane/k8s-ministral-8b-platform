variable "vpc_cidr" {
  description = "CIDR block of the environment VPC"
  type        = string
}

variable "availability_zones" {
  description = "Number of AZs to spread subnets across"
  type        = number
  validation {
    condition     = var.availability_zones >= 1 && var.availability_zones <= 8
    error_message = "availability_zones must be between 1 and 8: each tier gets half of the 2^subnet_newbits blocks."
  }

}

variable "subnet_newbits" {
  description = "Bits added to the VPC prefix for each subnet (e.g. /16 + 4 = /20)"
  type        = number
}

variable "nat_gateway" {
  description = "NAT gateway topology: none, one shared gateway, or one per AZ"
  type = object({
    enabled = bool
    per_az  = bool
  })
}

variable "dns" {
  description = "VPC DNS attributes"
  type = object({
    hostnames = bool
    support   = bool
  })
}

variable "map_public_ip_on_launch" {
  description = "Assign public IPs to instances launched in public subnets"
  type        = bool
}

variable "flow_logs" {
  description = "VPC flow logs to CloudWatch"
  type = object({
    enabled        = bool
    retention_days = number
  })
}

variable "gateway_endpoints" {
  description = "AWS services exposed through free gateway endpoints on the private route tables"
  type        = list(string)
}

variable "subnet_tags" {
  description = "Extra tags per subnet tier, on top of the Kubernetes discovery tags"
  type = object({
    private = map(string)
    public  = map(string)
  })
}
