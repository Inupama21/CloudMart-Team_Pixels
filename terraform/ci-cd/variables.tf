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
