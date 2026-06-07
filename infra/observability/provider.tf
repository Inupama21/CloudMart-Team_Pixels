# ==============================================================================
# AWS Provider — us-east-1 (N. Virginia) — Free Tier region
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "CloudMart"
      Team        = "Team_Pixels"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
