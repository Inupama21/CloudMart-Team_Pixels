# infra/modules/monitoring/main.tf

# Log groups for all 5 services
resource "aws_cloudwatch_log_group" "services" {
  for_each = toset([
    "/cloudmart/product-service",
    "/cloudmart/order-service",
    "/cloudmart/user-service",
    "/cloudmart/notification-service",
    "/cloudmart/frontend"
  ])

  name              = each.value
  retention_in_days = 30

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "cloudmart" {
  dashboard_name = "CloudMart-Production"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x = 0; y = 0; width = 12; height = 6
        properties = {
          title   = "Pod CPU by Service"
          period  = 60
          stat    = "Average"
          region  = var.aws_region
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", var.cluster_name, "Namespace", "cloudmart-prod", "PodName", "product-service"],
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", var.cluster_name, "Namespace", "cloudmart-prod", "PodName", "order-service"],
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", var.cluster_name, "Namespace", "cloudmart-prod", "PodName", "user-service"]
          ]
        }
      },
      {
        type   = "metric"
        x = 12; y = 0; width = 12; height = 6
        properties = {
          title   = "SQS Queue Depth"
          period  = 60
          stat    = "Average"
          region  = var.aws_region
          metrics = [["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "cloudmart-orders"]]
        }
      }
    ]
  })
}

# SNS alert topic
resource "aws_sns_topic" "cloudmart_alerts" {
  name = "cloudmart-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cloudmart_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Error rate alarm
resource "aws_cloudwatch_log_metric_filter" "product_errors" {
  name           = "product-service-errors"
  log_group_name = "/cloudmart/product-service"
  pattern        = "ERROR"

  metric_transformation {
    name      = "ProductServiceErrors"
    namespace = "CloudMart/Application"
    value     = "1"
  }

  depends_on = [aws_cloudwatch_log_group.services]
}

resource "aws_cloudwatch_metric_alarm" "product_error_rate" {
  alarm_name          = "product-service-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ProductServiceErrors"
  namespace           = "CloudMart/Application"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "product-service error rate too high"
  alarm_actions       = [aws_sns_topic.cloudmart_alerts.arn]
}