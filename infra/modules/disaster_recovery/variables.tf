variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "oidc_url" {
  description = "EKS OIDC provider URL without the https:// prefix"
  type        = string
}

variable "backup_retention_days" {
  description = "Number of days Velero backup objects remain in S3"
  type        = number
  default     = 30
}

