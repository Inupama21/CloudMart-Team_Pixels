variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS instance"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS nodes to allow database access"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "db_password" {
  description = "Master password for the RDS instance (leave null to auto-generate)"
  type        = string
  sensitive   = true
  default     = null
}

variable "multi_az" {
  description = "Whether RDS should maintain a synchronous standby in another AZ"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days automated RDS backups are retained"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Protect the RDS instance from accidental deletion"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether RDS deletion may proceed without a final snapshot"
  type        = bool
  default     = true
}
