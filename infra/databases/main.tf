# ==============================================================================
# RDS PostgreSQL (user-service)
# ==============================================================================

resource "aws_db_subnet_group" "rds" {
  name       = "cloudmart-rds-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name        = "cloudmart-rds-subnet-group"
    Environment = var.environment
    Service     = "user-service"
  }
}

resource "aws_security_group" "rds" {
  name        = "cloudmart-rds-sg-${var.environment}"
  description = "Security group for user-service RDS PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL access from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "cloudmart-rds-sg"
    Environment = var.environment
  }
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "users_db" {
  identifier           = "cloudmart-users-db-${var.environment}"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.micro" # Free tier eligible
  db_name              = "cloudmart"
  username             = "cloudmart"
  password             = var.db_password != null && var.db_password != "" ? var.db_password : random_password.db_password.result
  parameter_group_name = "default.postgres15"
  
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  skip_final_snapshot    = true # For dev/assignment purposes
  publicly_accessible    = false
  storage_encrypted      = true
  
  backup_retention_period = 7
  
  tags = {
    Environment = var.environment
    Service     = "user-service"
  }
}

# ==============================================================================
# DynamoDB Table (product-service)
# ==============================================================================

resource "aws_dynamodb_table" "products_table" {
  name           = "cloudmart-products-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST" # Cost-efficient for assignments
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Point-in-time recovery for backup compliance
  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Environment = var.environment
    Service     = "product-service"
  }
}

# ==============================================================================
# SQS Queue (order events)
# ==============================================================================

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
