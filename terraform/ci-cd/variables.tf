variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "repository_names" {
  description = "List of service names to create ECR repositories for"
  type        = list(string)
  default = [
    "frontend",
    "notification-service",
    "order-service",
    "product-service",
    "user-service"
  ]
}

variable "github_org_or_user" {
  description = "GitHub Organization or Username"
  type        = string
  default     = "Inupama21"
}

variable "github_repo" {
  description = "GitHub Repository Name"
  type        = string
  default     = "CloudMart-Team_Pixels"
}

