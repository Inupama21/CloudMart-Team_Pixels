variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "sqs_dlq_name" {
  description = "Name of the SQS Dead Letter Queue to monitor"
  type        = string
}

variable "rds_instance_identifier" {
  description = "Identifier of the RDS instance to monitor"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table to monitor"
  type        = string
}
