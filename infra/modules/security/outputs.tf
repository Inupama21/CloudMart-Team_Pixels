# infra/modules/security/outputs.tf

output "kms_key_arn" {
  description = "KMS key ARN - Member 4 needs this for RDS encryption"
  value       = aws_kms_key.cloudmart.arn
}

output "kms_key_alias" {
  value = aws_kms_alias.cloudmart.name
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.cloudmart.id
}

output "waf_acl_arn" {
  description = "WAF ARN - Member 6 needs this for ALB association"
  value       = aws_wafv2_web_acl.cloudmart.arn
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