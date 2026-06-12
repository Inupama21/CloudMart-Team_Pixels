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
