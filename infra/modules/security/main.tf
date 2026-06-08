# infra/modules/security/main.tf

# ─── KMS KEY ───────────────────────────────────────────────────────────────

resource "aws_kms_key" "cloudmart" {
  description             = "CloudMart encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
    Team        = var.team_id
    Owner       = "member5"
  }
}

resource "aws_kms_alias" "cloudmart" {
  name          = "alias/cloudmart-key"
  target_key_id = aws_kms_key.cloudmart.key_id
}

# ─── GUARDDUTY ─────────────────────────────────────────────────────────────

resource "aws_guardduty_detector" "cloudmart" {
  enable = true

  datasources {
    s3_logs { enable = true }
    kubernetes {
      audit_logs { enable = true }
    }
  }

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
    Team        = var.team_id
  }
}

# ─── WAF ───────────────────────────────────────────────────────────────────

resource "aws_wafv2_web_acl" "cloudmart" {
  name  = "cloudmart-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudMartWAF"
    sampled_requests_enabled   = true
  }

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
    Team        = var.team_id
  }
}

resource "aws_wafv2_web_acl_association" "cloudmart" {
  count        = var.alb_arn != "" ? 1 : 0
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.cloudmart.arn
}

# ─── IAM ROLES (IRSA) ──────────────────────────────────────────────────────

# product-service — DynamoDB only
resource "aws_iam_role" "product_service" {
  name = "cloudmart-product-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_url}:sub" = "system:serviceaccount:cloudmart-prod:product-service-sa"
        }
      }
    }]
  })

  tags = { Project = "cloudmart", Environment = var.environment }
}

resource "aws_iam_role_policy" "product_dynamodb" {
  role = aws_iam_role.product_service.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
                  "dynamodb:DeleteItem", "dynamodb:Scan", "dynamodb:Query"]
      Resource = "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.dynamodb_table_name}"
    }]
  })
}

# order-service — SQS only
resource "aws_iam_role" "order_service" {
  name = "cloudmart-order-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_url}:sub" = "system:serviceaccount:cloudmart-prod:order-service-sa"
        }
      }
    }]
  })

  tags = { Project = "cloudmart", Environment = var.environment }
}

resource "aws_iam_role_policy" "order_sqs" {
  role = aws_iam_role.order_service.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage", "sqs:GetQueueUrl"]
      Resource = var.sqs_queue_arn != "" ? var.sqs_queue_arn : "arn:aws:sqs:${var.aws_region}:${var.account_id}:cloudmart-orders"
    }]
  })
}

# notification-service — SQS consume + SES
resource "aws_iam_role" "notification_service" {
  name = "cloudmart-notification-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_url}:sub" = "system:serviceaccount:cloudmart-prod:notification-service-sa"
        }
      }
    }]
  })

  tags = { Project = "cloudmart", Environment = var.environment }
}

resource "aws_iam_role_policy" "notification_sqs_ses" {
  role = aws_iam_role.notification_service.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = var.sqs_queue_arn != "" ? var.sqs_queue_arn : "arn:aws:sqs:${var.aws_region}:${var.account_id}:cloudmart-orders"
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

# user-service — Secrets Manager only
resource "aws_iam_role" "user_service" {
  name = "cloudmart-user-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_url}:sub" = "system:serviceaccount:cloudmart-prod:user-service-sa"
        }
      }
    }]
  })

  tags = { Project = "cloudmart", Environment = var.environment }
}

resource "aws_iam_role_policy" "user_secrets" {
  role = aws_iam_role.user_service.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:cloudmart/prod/db-password*"
    }]
  })
}