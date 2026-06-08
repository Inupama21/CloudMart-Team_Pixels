# ── Networking
output "vpc_id" {
  value = module.networking.vpc_id
}

# ── Database
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.database.rds_endpoint
}

output "rds_port" {
  description = "The port the RDS instance is listening on"
  value       = module.database.rds_port
}

output "rds_db_name" {
  description = "The database name"
  value       = module.database.rds_db_name
}

output "db_password" {
  description = "The database password (auto-generated or user-provided)"
  value       = module.database.db_password
  sensitive   = true
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for products"
  value       = module.database.dynamodb_table_name
}

output "rds_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.database.rds_instance_identifier
}

# ── Messaging
output "sqs_queue_url" {
  description = "URL of the SQS queue for order events"
  value       = module.messaging.sqs_queue_url
}

output "sqs_dlq_url" {
  description = "URL of the dead-letter queue"
  value       = module.messaging.sqs_dlq_url
}

output "sqs_dlq_name" {
  description = "The SQS dead-letter queue name"
  value       = module.messaging.sqs_dlq_name
}
