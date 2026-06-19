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
  default = "production"
}

variable "cluster_name" {
  description = "Single EKS cluster hosting production and staging namespaces"
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
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ── Database
variable "db_password" {
  description = "Master password for the RDS instance (leave null to auto-generate)"
  type        = string
  sensitive   = true
  default     = null
}

# ── Security
variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN for WAF association — leave empty until ALB is created by Member 6"
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
  default     = true
}

variable "enable_bastion" {
  description = "Create an SSM-managed bastion"
  type        = bool
  default     = true
}

variable "bastion_allowed_cidrs" {
  description = "Optional SSH CIDRs; leave empty to require SSM Session Manager"
  type        = list(string)
  default     = []
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EKS managed-node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "monthly_budget_usd" {
  description = "Production monthly cost threshold"
  type        = number
  default     = 100
}

variable "budget_notification_emails" {
  description = "Recipients for forecasted and actual AWS Budget alerts"
  type        = list(string)
  default     = ["kavisekarais.21@uom.lk"]
}
