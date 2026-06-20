output "kms_key_arn" {
  description = "KMS key protecting application secrets"
  value       = aws_kms_key.cloudmart.arn
}

output "kms_key_alias" {
  value = aws_kms_alias.cloudmart.name
}

output "application_secret_arn" {
  value = aws_secretsmanager_secret.application.arn
}

output "application_secret_name" {
  value = aws_secretsmanager_secret.application.name
}

output "guardduty_detector_id" {
  value = var.enable_guardduty ? aws_guardduty_detector.cloudmart[0].id : null
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.cloudmart.arn
}

output "product_service_role_arn" {
  value = aws_iam_role.product_service.arn
}

output "order_service_role_arn" {
  value = aws_iam_role.order_service.arn
}

output "notification_service_role_arn" {
  value = aws_iam_role.notification_service.arn
}

output "user_service_role_arn" {
  value = aws_iam_role.user_service.arn
}
