# infra/modules/observability/variables.tf

variable "environment" {
  description = "Environment name (staging or production)"
  type        = string
}

variable "sqs_dlq_name" {
  description = "Name of the SQS Dead Letter Queue to monitor"
  type        = string
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

# Added by Member 5
variable "cluster_name" {
  description = "EKS cluster name for ContainerInsights metrics"
  type        = string
  default     = "cloudmart-cluster"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}