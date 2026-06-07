#input variables 

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public Subnets – Load Balancer Tier
# Two subnets across us-east-1a and us-east-1b

variable "public_subnets" {
  description = "Map of public subnets (Load Balancer tier)"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "az-a" = { cidr = "10.0.1.0/24", az = "us-east-1a" }
    "az-b" = { cidr = "10.0.2.0/24", az = "us-east-1b" }
  }
}

# Private Application Subnets – EKS Cluster Tier

variable "private_app_subnets" {
  description = "Map of private subnets for the EKS cluster (Application tier)"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "az-a" = { cidr = "10.0.10.0/24", az = "us-east-1a" }
    "az-b" = { cidr = "10.0.11.0/24", az = "us-east-1b" }
  }
}

# Private Data Subnets – Database Tier (RDS / ElastiCache)

variable "private_data_subnets" {
  description = "Map of private subnets for databases (Data tier)"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "az-a" = { cidr = "10.0.20.0/24", az = "us-east-1a" }
    "az-b" = { cidr = "10.0.21.0/24", az = "us-east-1b" }
  }
}
