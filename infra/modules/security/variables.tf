# infra/modules/security/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "oidc_url" {
  description = "EKS OIDC provider URL (without https://)"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN for WAF association - leave empty until ALB exists"
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for products - get from Member 4"
  type        = string
  default     = "cloudmart-products"
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN - get from Member 4"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (production or staging)"
  type        = string
  default     = "production"
}

variable "team_id" {
  description = "Your group/team ID for tagging"
  type        = string
  default     = "team-pixels"
}