output "state_bucket_name" {
  description = "Copy this value into environments/*/backend.tf"
  value       = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  description = "Copy this value into environments/*/backend.tf"
  value       = aws_dynamodb_table.tf_lock.name
}

output "aws_region" {
  value = var.aws_region
}
