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
    ManagedBy   = "terraform"
    CostCenter  = "cloudmart-production"
  }
}

# ── Networking ────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true
  common_tags          = local.common_tags
}

# ── Database (RDS + DynamoDB) ─────────────────────────────────
module "database" {
  source = "../../modules/database"

  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  eks_security_group_id = module.networking.eks_node_security_group_id
  environment           = var.environment
  db_password           = var.db_password
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
}
