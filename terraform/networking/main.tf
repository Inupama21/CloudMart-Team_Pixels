
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
  region = var.aws_region
}


locals {
  common_tags = {
    Project     = "cloudmart"
    Environment = "prod"
    Owner       = "member01"
  }
}

#vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-igw"
  })
}


# --- Public Subnets (Load Balancer tier) ------------------------------------
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-public-${each.key}"
    Tier = "public"
  })
}

# --- Private Application Subnets (EKS worker nodes) ------------------------
resource "aws_subnet" "private_app" {
  for_each = var.private_app_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.common_tags, {
    Name                                        = "cloudmart-prod-private-app-${each.key}"
    Tier                                        = "private-app"
    # Required by EKS to discover subnets automatically
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/cloudmart-prod-eks"  = "shared"
  })
}

# --- Private Data Subnets (RDS / ElastiCache) -------------------------------
resource "aws_subnet" "private_data" {
  for_each = var.private_data_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-private-data-${each.key}"
    Tier = "private-data"
  })
}

# 4. Elastic IP + NAT Gateway (single, in first public subnet)

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-nat-eip"
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["az-a"].id   # placed in the first public subnet

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-nat-gw"
  })

  depends_on = [aws_internet_gateway.igw]
}
# 5. Route Tables

# --- Public Route Table (IGW route) -----------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-public-rt"
  })
}

# Associate BOTH public subnets with the public route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Table (NAT Gateway route) --------------------------------
# One shared private route table – all private subnets route egress via NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.common_tags, {
    Name = "cloudmart-prod-private-rt"
  })
}

# Associate Private App subnets
resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Associate Private Data subnets
resource "aws_route_table_association" "private_data" {
  for_each = aws_subnet.private_data

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
