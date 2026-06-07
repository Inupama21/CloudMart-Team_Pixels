output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.users_db.endpoint
}

output "rds_port" {
  description = "The port the RDS instance is listening on"
  value       = aws_db_instance.users_db.port
}

output "rds_db_name" {
  description = "The database name"
  value       = aws_db_instance.users_db.db_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for products"
  value       = aws_dynamodb_table.products_table.name
}

output "sqs_queue_url" {
  description = "URL of the SQS queue for order events"
  value       = aws_sqs_queue.order_events.url
}

output "sqs_dlq_url" {
  description = "URL of the dead-letter queue"
  value       = aws_sqs_queue.order_events_dlq.url
}

output "db_password" {
  description = "The database password (auto-generated or user-provided)"
  value       = var.db_password != null && var.db_password != "" ? var.db_password : random_password.db_password.result
  sensitive   = true
}

output "rds_instance_identifier" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.users_db.identifier
}

output "sqs_dlq_name" {
  description = "The SQS dead-letter queue name"
  value       = aws_sqs_queue.order_events_dlq.name
}


