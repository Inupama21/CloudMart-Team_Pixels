variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region used to resolve endpoint service names"
  type        = string
}

variable "account_id" {
  description = "AWS account ID used in private endpoint policies"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet discovery tags"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per availability zone"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private application subnet CIDRs, one per availability zone"
  type        = list(string)
}

variable "data_subnet_cidrs" {
  description = "Isolated data subnet CIDRs, one per availability zone"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones used by all subnet tiers"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for application subnet egress"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs and a rejected-traffic query"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention for VPC flow logs"
  type        = number
  default     = 30
}

variable "enable_bastion" {
  description = "Create a small SSM-managed bastion in the first public subnet"
  type        = bool
  default     = false
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion"
  type        = string
  default     = "t2.micro"
}

variable "bastion_allowed_cidrs" {
  description = "Optional administrator CIDRs permitted to SSH; leave empty to use SSM only"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}
