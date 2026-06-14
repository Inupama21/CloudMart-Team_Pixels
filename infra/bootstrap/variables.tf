
variable "aws_region" {
  description = "AWS region to create the state bucket in"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state"
  type        = string
  # Convention: cloudmart-tf-state-<account-id>
  # Override in terraform.tfvars
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "cloudmart-tf-locks"
}
