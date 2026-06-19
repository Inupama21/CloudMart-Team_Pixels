terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Team        = var.team
    Owner       = var.owner_email
    ManagedBy   = "terraform"
    CostCenter  = "cloudmart-production"
  }
}

# ── Networking ────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  project               = var.project
  environment           = var.environment
  aws_region            = var.aws_region
  account_id            = var.account_id
  cluster_name          = var.cluster_name
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  data_subnet_cidrs     = var.data_subnet_cidrs
  availability_zones    = var.availability_zones
  enable_nat_gateway    = true
  enable_flow_logs      = true
  enable_bastion        = var.enable_bastion
  bastion_allowed_cidrs = var.bastion_allowed_cidrs
  common_tags           = local.common_tags
}

# -- Managed Kubernetes -------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  cluster_name                = var.cluster_name
  private_subnet_ids          = module.networking.private_subnet_ids
  node_security_group_id      = module.networking.eks_node_security_group_id
  endpoint_public_access      = true
  cluster_public_access_cidrs = var.cluster_public_access_cidrs
  node_instance_types         = var.node_instance_types
  node_capacity_type          = "ON_DEMAND"
  node_desired_size           = 2
  node_min_size               = 2
  node_max_size               = 4
  cicd_role_arn               = "arn:aws:iam::${var.account_id}:role/github-actions-cloudmart-deploy-role"
  common_tags                 = local.common_tags
}

# ── Database (RDS + DynamoDB) ─────────────────────────────────
module "database" {
  source = "../../modules/database"

  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.data_subnet_ids
  eks_security_group_id     = module.networking.eks_node_security_group_id
  bastion_security_group_id = module.networking.bastion_security_group_id
  environment               = var.environment
  db_password               = var.db_password
  multi_az                  = true
  backup_retention_days     = 7
  deletion_protection       = true
  skip_final_snapshot       = false
  rds_kms_key_arn           = var.rds_kms_key_arn
}

# ── Messaging (SQS) ──────────────────────────────────────────
module "messaging" {
  source = "../../modules/messaging"

  environment = var.environment
}

# ── Observability (CloudWatch) ────────────────────────────────
module "observability" {
  source = "../../modules/observability"

  environment             = var.environment
  rds_instance_identifier = module.database.rds_instance_identifier
  dynamodb_table_name     = module.database.dynamodb_table_name
  sqs_dlq_name            = module.messaging.sqs_dlq_name
  cluster_name            = module.eks.cluster_name
  aws_region              = var.aws_region
  alert_email             = var.alert_email
}

# ── Security ───────────────────────────────────────
module "security" {
  source = "../../modules/security"

  aws_region            = var.aws_region
  account_id            = var.account_id
  oidc_url              = module.eks.oidc_provider_url
  alb_arn               = var.alb_arn
  dynamodb_table_name   = module.database.dynamodb_table_name
  sqs_queue_arn         = module.messaging.sqs_queue_arn
  db_host               = module.database.rds_address
  db_port               = module.database.rds_port
  db_name               = module.database.rds_db_name
  db_password           = module.database.db_password
  kubernetes_namespaces = ["cloudmart-prod"]
  environment           = var.environment
  team_id               = var.project
  enable_guardduty      = var.enable_guardduty
}

# -- Cost management ----------------------------------------------------------
module "cost_management" {
  source = "../../modules/cost_management"

  project             = var.project
  environment         = var.environment
  monthly_budget_usd  = var.monthly_budget_usd
  notification_emails = var.budget_notification_emails
}

# -- Disaster recovery --------------------------------------------------------
module "disaster_recovery" {
  source = "../../modules/disaster_recovery"

  project               = var.project
  environment           = var.environment
  aws_region            = var.aws_region
  account_id            = var.account_id
  oidc_url              = module.eks.oidc_provider_url
  backup_retention_days = 30
}
