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

# -- Preserved shared Kubernetes cluster --------------------------------------
# The live cluster was created by eksctl and contains running workloads. Read it
# instead of attempting to create or import a second cluster with the same name.
data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

locals {
  existing_cluster_oidc_url = replace(
    data.aws_eks_cluster.existing.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
}

# This peering belongs to the pre-existing cluster/network stack. Search both
# requester/accepter directions because the cluster VPC created the connection.
data "aws_vpc_peering_connections" "existing_cluster" {
  filter {
    name   = "status-code"
    values = ["active"]
  }

  filter {
    name = "requester-vpc-info.vpc-id"
    values = [
      module.networking.vpc_id,
      data.aws_eks_cluster.existing.vpc_config[0].vpc_id
    ]
  }

  filter {
    name = "accepter-vpc-info.vpc-id"
    values = [
      module.networking.vpc_id,
      data.aws_eks_cluster.existing.vpc_config[0].vpc_id
    ]
  }
}

locals {
  existing_cluster_vpc_peering_id = one(data.aws_vpc_peering_connections.existing_cluster.ids)
}

check "single_active_cluster_peering" {
  assert {
    condition     = length(data.aws_vpc_peering_connections.existing_cluster.ids) == 1
    error_message = "Expected exactly one active VPC peering connection between production and the preserved EKS VPC."
  }
}

resource "aws_route" "production_app_to_existing_cluster" {
  for_each = toset(module.networking.private_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.existing_cluster_vpc_cidr
  vpc_peering_connection_id = local.existing_cluster_vpc_peering_id
}

resource "aws_route" "production_data_to_existing_cluster" {
  route_table_id            = module.networking.data_route_table_id
  destination_cidr_block    = var.existing_cluster_vpc_cidr
  vpc_peering_connection_id = local.existing_cluster_vpc_peering_id
}

# ── Database (RDS + DynamoDB) ─────────────────────────────────
module "database" {
  source = "../../modules/database"

  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.data_subnet_ids
  eks_security_group_id     = null
  eks_allowed_cidrs         = [var.existing_cluster_vpc_cidr]
  bastion_security_group_id = module.networking.bastion_security_group_id
  environment               = var.environment
  db_password               = var.db_password
  # Current account plan enforces Free Tier limits. Upgrade the plan before
  # enabling Multi-AZ or automated backup retention.
  multi_az              = false
  backup_retention_days = 0
  deletion_protection   = true
  skip_final_snapshot   = false
  rds_kms_key_arn       = var.rds_kms_key_arn
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
  cluster_name            = data.aws_eks_cluster.existing.name
  aws_region              = var.aws_region
  alert_email             = var.alert_email
}

# ── Security ───────────────────────────────────────
module "security" {
  source = "../../modules/security"

  aws_region            = var.aws_region
  account_id            = var.account_id
  oidc_url              = local.existing_cluster_oidc_url
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
  oidc_url              = local.existing_cluster_oidc_url
  backup_retention_days = 30
}
