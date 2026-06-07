# infra/modules/monitoring/variables.tf

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cloudmart-cluster"
}

variable "aws_region" {
  type    = string
}

variable "environment" {
  type    = string
  default = "production"
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alerts"
  type        = string
}