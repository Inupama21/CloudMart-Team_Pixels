resource "aws_db_subnet_group" "rds" {
  name       = "cloudmart-rds-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  # The existing production database is still attached to the original subnet
  # group members. Moving it is a separate migration and must not be attempted
  # as part of the networking/security rollout.
  lifecycle {
    ignore_changes = [subnet_ids]
  }

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

  dynamic "ingress" {
    for_each = var.eks_security_group_id == null ? [] : [var.eks_security_group_id]
    content {
      description     = "Allow PostgreSQL access from EKS nodes"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.eks_allowed_cidrs)
    content {
      description = "Allow PostgreSQL access from a peered EKS VPC"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.eks_allowed_cidrs)
    content {
      description = "Allow ICMP for Path MTU Discovery (PMTUD) over VPC Peering"
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.bastion_security_group_id == null ? [] : [var.bastion_security_group_id]
    content {
      description     = "Administrative PostgreSQL access from the SSM bastion"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
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

resource "aws_db_parameter_group" "postgres" {
  name   = "cloudmart-postgres15-${var.environment}"
  family = "postgres15"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Environment = var.environment
    Service     = "user-service"
  }
}

resource "aws_kms_key" "database" {
  description             = "CloudMart ${var.environment} database encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "database" {
  name          = "alias/cloudmart-${var.environment}-database"
  target_key_id = aws_kms_key.database.key_id
}

resource "aws_db_instance" "users_db" {
  identifier           = "cloudmart-users-db-${var.environment}"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro" # Free tier eligible
  db_name              = "cloudmart"
  username             = "cloudmart"
  password             = var.db_password != null && var.db_password != "" ? var.db_password : random_password.db_password.result
  parameter_group_name = aws_db_parameter_group.postgres.name

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                  = var.multi_az
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "cloudmart-users-db-${var.environment}-final"
  publicly_accessible       = false
  storage_encrypted         = true
  kms_key_id                = var.rds_kms_key_arn != null ? var.rds_kms_key_arn : aws_kms_key.database.arn

  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"
  copy_tags_to_snapshot   = true

  tags = {
    Environment = var.environment
    Service     = "user-service"
  }
}

resource "aws_dynamodb_table" "products_table" {
  name         = "cloudmart-products-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # Cost-efficient for assignments
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Point-in-time recovery for backup compliance
  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.database.arn
  }

  tags = {
    Environment = var.environment
    Service     = "product-service"
  }
}
