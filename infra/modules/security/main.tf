terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

locals {
  product_subjects = [
    for namespace in var.kubernetes_namespaces :
    "system:serviceaccount:${namespace}:product-service-sa"
  ]
  order_subjects = [
    for namespace in var.kubernetes_namespaces :
    "system:serviceaccount:${namespace}:order-service-sa"
  ]
  notification_subjects = [
    for namespace in var.kubernetes_namespaces :
    "system:serviceaccount:${namespace}:notification-service-sa"
  ]
  user_subjects = [
    for namespace in var.kubernetes_namespaces :
    "system:serviceaccount:${namespace}:user-service-sa"
  ]
}

resource "aws_kms_key" "cloudmart" {
  description             = "CloudMart ${var.environment} application secrets key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
    Team        = var.team_id
  }
}

resource "aws_kms_alias" "cloudmart" {
  name          = "alias/cloudmart-${var.environment}-application-secrets"
  target_key_id = aws_kms_key.cloudmart.key_id
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "application" {
  name                    = "cloudmart/${var.environment}/application"
  description             = "CloudMart database credentials and JWT signing key"
  kms_key_id              = aws_kms_key.cloudmart.arn
  recovery_window_in_days = 7

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
    Team        = var.team_id
  }
}

resource "aws_secretsmanager_secret_version" "application" {
  secret_id = aws_secretsmanager_secret.application.id
  secret_string = jsonencode({
    db_host     = var.db_host
    db_port     = tostring(var.db_port)
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    db_sslmode  = "require"
    jwt_secret  = random_password.jwt_secret.result
  })
}

resource "aws_guardduty_detector" "cloudmart" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
    Team        = var.team_id
  }
}

resource "aws_wafv2_web_acl" "cloudmart" {
  name  = "cloudmart-${var.environment}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CloudMartCommonRules-${var.environment}"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CloudMartBadInputs-${var.environment}"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CloudMartIpReputation-${var.environment}"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudMartWAF-${var.environment}"
    sampled_requests_enabled   = true
  }

  tags = {
    Project     = "cloudmart"
    Environment = var.environment
    Team        = var.team_id
  }
}

resource "aws_wafv2_web_acl_association" "cloudmart" {
  count = var.alb_arn != "" ? 1 : 0

  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.cloudmart.arn
}

resource "aws_iam_role" "product_service" {
  name = "cloudmart-${var.environment}-product-service-role"

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
          "${var.oidc_url}:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "${var.oidc_url}:sub" = local.product_subjects
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "product_dynamodb" {
  role = aws_iam_role.product_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ]
      Resource = "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.dynamodb_table_name}"
    }]
  })
}

resource "aws_iam_role" "order_service" {
  name = "cloudmart-${var.environment}-order-service-role"

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
          "${var.oidc_url}:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "${var.oidc_url}:sub" = local.order_subjects
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "order_sqs" {
  role = aws_iam_role.order_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:SendMessage"
      ]
      Resource = var.sqs_queue_arn
    }]
  })
}

resource "aws_iam_role" "notification_service" {
  name = "cloudmart-${var.environment}-notification-service-role"

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
          "${var.oidc_url}:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "${var.oidc_url}:sub" = local.notification_subjects
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "notification_sqs_ses" {
  role = aws_iam_role.notification_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = var.ses_identity_arns
      }
    ]
  })
}

resource "aws_iam_role" "user_service" {
  name = "cloudmart-${var.environment}-user-service-role"

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
          "${var.oidc_url}:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "${var.oidc_url}:sub" = local.user_subjects
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "user_secrets" {
  role = aws_iam_role.user_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.application.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = aws_kms_key.cloudmart.arn
      }
    ]
  })
}
