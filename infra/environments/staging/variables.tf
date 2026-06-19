variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "cloudmart"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "cluster_name" {
  description = "Shared production-owned EKS cluster name"
  type        = string
  default     = "cloudmart-cluster"
}

variable "team" {
  description = "Team tag applied to all resources"
  type        = string
  default     = "Team-Pixels"
}

variable "owner_email" {
  description = "Owner tag applied to all resources"
  type        = string
  default     = "team-pixels@example.com"
}

# ── Network
variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.20.0/24", "10.1.21.0/24"]
}

variable "production_vpc_id" {
  description = "VPC ID output from the production environment"
  type        = string
}

variable "production_vpc_cidr" {
  description = "Production VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "production_private_route_table_ids" {
  description = "Production application route table IDs"
  type        = list(string)
}

variable "production_eks_security_group_id" {
  description = "Production EKS node security group ID"
  type        = string
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

# ── Database
variable "db_password" {
  description = "Master password for the RDS instance (leave null to auto-generate)"
  type        = string
  sensitive   = true
  default     = null
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "oidc_url" {
  description = "EKS OIDC Provider URL without https://"
  type        = string
}

# ── Security 
variable "alb_arn" {
  description = "ALB ARN for WAF association — leave empty until ALB is created"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "savindipaboda@gmail.com"
}

variable "enable_guardduty" {
  description = "Enable GuardDuty"
  type        = bool
  default     = false
}

variable "monthly_budget_usd" {
  description = "Staging monthly cost threshold"
  type        = number
  default     = 50
}

variable "budget_notification_emails" {
  description = "Recipients for forecasted and actual AWS Budget alerts"
  type        = list(string)
  default     = ["kavisekarais.21@uom.lk"]
}
