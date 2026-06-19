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

output "db_password" {
  description = "The database password (auto-generated or user-provided)"
  value       = var.db_password != null && var.db_password != "" ? var.db_password : random_password.db_password.result
  sensitive   = true
}

output "rds_instance_identifier" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.users_db.identifier
}

output "database_kms_key_arn" {
  description = "Customer-managed KMS key used by RDS and DynamoDB"
  value       = aws_kms_key.database.arn
}
