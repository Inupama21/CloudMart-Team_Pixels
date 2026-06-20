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
    Team        = var.team
    Owner       = var.owner_email
    ManagedBy   = "terraform"
    CostCenter  = "cloudmart-staging"
  }
}

# ── Networking ────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  project              = var.project
  environment          = var.environment
  aws_region           = var.aws_region
  account_id           = var.account_id
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  enable_flow_logs     = true
  enable_bastion       = false
  common_tags          = local.common_tags
}

# The assignment uses one EKS cluster. Staging data remains in a separate VPC and is reachable
# only through same-account VPC peering and explicit routes.
resource "aws_vpc_peering_connection" "shared_cluster" {
  vpc_id      = module.networking.vpc_id
  peer_vpc_id = var.production_vpc_id
  auto_accept = true

  tags = merge(local.common_tags, {
    Name = "cloudmart-production-to-staging"
  })
}

resource "aws_vpc_peering_connection_options" "shared_cluster" {
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_cluster.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "staging_app_to_production" {
  for_each = toset(module.networking.private_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.production_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_cluster.id
}

resource "aws_route" "staging_data_to_production" {
  route_table_id            = module.networking.data_route_table_id
  destination_cidr_block    = var.production_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_cluster.id
}

resource "aws_route" "production_app_to_staging" {
  for_each = toset(var.production_private_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_cluster.id
}

# ── Database (RDS + DynamoDB) ─────────────────────────────────
module "database" {
  source = "../../modules/database"

  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.data_subnet_ids
  eks_security_group_id = var.production_eks_security_group_id
  bastion_security_group_id = null
  environment           = var.environment
  db_password           = var.db_password
  multi_az              = false
  backup_retention_days = 7
  deletion_protection   = false
  skip_final_snapshot   = true

  depends_on = [aws_vpc_peering_connection.shared_cluster]
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
  cluster_name            = "cloudmart-cluster"
  aws_region              = var.aws_region
  alert_email             = var.alert_email
}

# ── Security ───────────────────────────────────────
module "security" {
  source = "../../modules/security"

  aws_region          = var.aws_region
  account_id          = var.account_id
  oidc_url            = var.oidc_url
  alb_arn             = var.alb_arn
  dynamodb_table_name = module.database.dynamodb_table_name
  sqs_queue_arn       = module.messaging.sqs_queue_arn
  db_host             = module.database.rds_address
  db_port             = module.database.rds_port
  db_name             = module.database.rds_db_name
  db_password         = module.database.db_password
  kubernetes_namespaces = ["cloudmart-staging"]
  environment         = var.environment
  team_id             = var.project
  enable_guardduty    = var.enable_guardduty
}

# -- Cost management ----------------------------------------------------------
module "cost_management" {
  source = "../../modules/cost_management"

  project             = var.project
  environment         = var.environment
  monthly_budget_usd  = var.monthly_budget_usd
  notification_emails = var.budget_notification_emails
}
