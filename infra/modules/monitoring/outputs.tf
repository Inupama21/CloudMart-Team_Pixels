# infra/modules/monitoring/outputs.tf

output "sns_topic_arn" {
  value = aws_sns_topic.cloudmart_alerts.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.cloudmart.dashboard_name
}