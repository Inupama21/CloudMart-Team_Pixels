# ==============================================================================
# Log Groups (for EKS FluentBit / CloudWatch Agent to send logs to)
# ==============================================================================

resource "aws_cloudwatch_log_group" "product_service" {
  name              = "/cloudmart/${var.environment}/product-service"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/cloudmart/${var.environment}/order-service"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/cloudmart/${var.environment}/user-service"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "notification_service" {
  name              = "/cloudmart/${var.environment}/notification-service"
  retention_in_days = 14
}

# ==============================================================================
# Metric Filters
# ==============================================================================

resource "aws_cloudwatch_log_metric_filter" "order_service_errors" {
  name           = "OrderServiceErrors-${var.environment}"
  pattern        = "\"ERROR\""
  log_group_name = aws_cloudwatch_log_group.order_service.name

  metric_transformation {
    name      = "ErrorCount"
    namespace = "CloudMart/${var.environment}/OrderService"
    value     = "1"
  }
}

# ==============================================================================
# Alarms
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "CloudMart-DLQ-NotEmpty-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when dead-letter queue has messages (failed orders/notifications)"
  
  dimensions = {
    QueueName = var.sqs_dlq_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "CloudMart-RDS-HighCPU-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when RDS CPU exceeds 80%"
  
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }
}

# ==============================================================================
# Dashboard
# ==============================================================================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "CloudMart-Overview-${var.environment}"

  dashboard_body = templatefile("${path.module}/dashboard.json", {
    environment             = var.environment
    rds_instance_identifier = var.rds_instance_identifier
    dynamodb_table_name     = var.dynamodb_table_name
    sqs_dlq_name            = var.sqs_dlq_name
  })
}
