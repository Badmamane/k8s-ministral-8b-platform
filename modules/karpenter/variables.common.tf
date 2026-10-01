variable "project" {
  description = "Project slug used as resource name prefix"
  type        = string
}

variable "env" {
  description = "Environment name (dev, stg, prd)"
  type        = string
}

variable "tags" {
  description = "Tags propagated to resources created outside Terraform (launch templates, controllers)"
  type        = map(string)
}
