resource "aws_sqs_queue" "order_events_dlq" {
  name = "cloudmart-order-events-dlq-${var.environment}"

  sqs_managed_sse_enabled = true

  tags = {
    Environment = var.environment
    Service     = "order-service"
  }
}

resource "aws_sqs_queue" "order_events" {
  name = "cloudmart-order-events-${var.environment}"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 days

  sqs_managed_sse_enabled = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_events_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
    Service     = "order-service"
  }
}
