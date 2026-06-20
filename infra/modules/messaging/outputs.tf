output "sqs_queue_url" {
  description = "URL of the SQS queue for order events"
  value       = aws_sqs_queue.order_events.url
}

output "sqs_dlq_url" {
  description = "URL of the dead-letter queue"
  value       = aws_sqs_queue.order_events_dlq.url
}

output "sqs_dlq_name" {
  description = "The SQS dead-letter queue name"
  value       = aws_sqs_queue.order_events_dlq.name
}

output "sqs_queue_arn" {
  description = "ARN of the SQS orders queue — needed by Member 5 for IAM policies"
  value       = aws_sqs_queue.order_events.arn
}
