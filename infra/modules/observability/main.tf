# infra/modules/observability/main.tf

# ── Log Groups ──────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "product_service" {
  name              = "/cloudmart/${var.environment}/product-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/cloudmart/${var.environment}/order-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/cloudmart/${var.environment}/user-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "notification_service" {
  name              = "/cloudmart/${var.environment}/notification-service"
  retention_in_days = 30
}

# Added by Member 5 — frontend was missing
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/cloudmart/${var.environment}/frontend"
  retention_in_days = 30
}

# ── SNS Alerts (Member 5) ───────────────────────────────────────────────────

resource "aws_sns_topic" "cloudmart_alerts" {
  name = "cloudmart-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cloudmart_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── Metric Filters ──────────────────────────────────────────────────────────

# From observability module — order-service errors
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

# Added by Member 5 — product-service errors
resource "aws_cloudwatch_log_metric_filter" "product_service_errors" {
  name           = "ProductServiceErrors-${var.environment}"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.product_service.name

  metric_transformation {
    name      = "ProductServiceErrors"
    namespace = "CloudMart/Application"
    value     = "1"
  }
}

# ── Alarms ──────────────────────────────────────────────────────────────────

# From observability module — DLQ not empty
resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "CloudMart-DLQ-NotEmpty-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Dead-letter queue has messages — orders or notifications are failing"
  alarm_actions       = [aws_sns_topic.cloudmart_alerts.arn]

  dimensions = {
    QueueName = var.sqs_dlq_name
  }
}

# From observability module — RDS high CPU
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "CloudMart-RDS-HighCPU-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.cloudmart_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }
}

# Added by Member 5 — product-service error rate
resource "aws_cloudwatch_metric_alarm" "product_error_rate" {
  alarm_name          = "product-service-high-error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ProductServiceErrors"
  namespace           = "CloudMart/Application"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "product-service error rate too high"
  alarm_actions       = [aws_sns_topic.cloudmart_alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.product_service_errors]
}

# Added by Member 5 — order-service high CPU
resource "aws_cloudwatch_metric_alarm" "order_service_high_cpu" {
  alarm_name          = "order-service-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "pod_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "order-service CPU above 80%"
  alarm_actions       = [aws_sns_topic.cloudmart_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    Namespace   = "cloudmart-prod"
    PodName     = "order-service"
  }
}

# ── Dashboard ───────────────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "CloudMart-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
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
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Pod Memory by Service"
          period  = 60
          stat    = "Average"
          region  = var.aws_region
          metrics = [
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", var.cluster_name, "Namespace", "cloudmart-prod", "PodName", "product-service"],
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", var.cluster_name, "Namespace", "cloudmart-prod", "PodName", "order-service"],
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", var.cluster_name, "Namespace", "cloudmart-prod", "PodName", "user-service"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "SQS Queue Depth"
          period  = 60
          stat    = "Average"
          region  = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "cloudmart-order-events-${var.environment}"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "RDS CPU"
          period  = 60
          stat    = "Average"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_identifier]
          ]
        }
      }
    ]
  })
}
