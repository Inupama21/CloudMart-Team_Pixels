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

# ── Security
output "kms_key_arn" {
  description = "KMS key ARN — Member 4 needs this for RDS encryption"
  value       = module.security.kms_key_arn
}

output "waf_acl_arn" {
  description = "WAF ACL ARN — Member 6 needs this for ALB association"
  value       = module.security.waf_acl_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.security.guardduty_detector_id
}

output "product_service_role_arn" {
  description = "IAM role ARN for product-service IRSA"
  value       = module.security.product_service_role_arn
}

output "order_service_role_arn" {
  description = "IAM role ARN for order-service IRSA"
  value       = module.security.order_service_role_arn
}

output "notification_service_role_arn" {
  description = "IAM role ARN for notification-service IRSA"
  value       = module.security.notification_service_role_arn
}

output "user_service_role_arn" {
  description = "IAM role ARN for user-service IRSA"
  value       = module.security.user_service_role_arn
}

# Observability outputs
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.observability.dashboard_name
}

output "alerts_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = module.observability.sns_topic_arn
}
