variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "oidc_url" {
  description = "EKS OIDC provider URL without https://"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN for WAF association; leave empty until the ALB exists"
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "Product table name"
  type        = string
}

variable "sqs_queue_arn" {
  description = "Orders queue ARN"
  type        = string
}

variable "db_host" {
  description = "RDS hostname"
  type        = string
}

variable "db_port" {
  description = "RDS port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "cloudmart"
}

variable "db_password" {
  description = "PostgreSQL password stored in Secrets Manager"
  type        = string
  sensitive   = true
}

variable "kubernetes_namespaces" {
  description = "Namespaces allowed to assume application workload roles"
  type        = list(string)
  default     = ["cloudmart-prod", "cloudmart-staging"]
}

variable "ses_identity_arns" {
  description = "Verified SES identity ARNs allowed to send CloudMart email"
  type        = list(string)
  default     = ["*"]
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "team_id" {
  description = "Team tag"
  type        = string
  default     = "team-pixels"
}

variable "enable_guardduty" {
  description = "Enable GuardDuty threat detection"
  type        = bool
  default     = true
}
