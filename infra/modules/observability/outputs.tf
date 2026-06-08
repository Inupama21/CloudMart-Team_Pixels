output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "log_group_names" {
  description = "Map of service name to CloudWatch log group name"
  value = {
    product_service      = aws_cloudwatch_log_group.product_service.name
    order_service        = aws_cloudwatch_log_group.order_service.name
    user_service         = aws_cloudwatch_log_group.user_service.name
    notification_service = aws_cloudwatch_log_group.notification_service.name
  }
}
