output "velero_bucket_name" {
  description = "S3 bucket used by Velero"
  value       = aws_s3_bucket.velero.bucket
}

output "velero_role_arn" {
  description = "IRSA role used by the Velero service account"
  value       = aws_iam_role.velero.arn
}

