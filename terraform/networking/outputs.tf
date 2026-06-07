
output "vpc_id" {
  description = "The ID of the CloudMart VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

# ---------------------------------------------------------------------------
# Public Subnet outputs
# ---------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "Map of public subnet IDs keyed by AZ label (az-a, az-b)"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "public_subnet_cidrs" {
  description = "Map of public subnet CIDR blocks"
  value       = { for k, v in aws_subnet.public : k => v.cidr_block }
}

# ---------------------------------------------------------------------------
# Private Application Subnet outputs (EKS)
# ---------------------------------------------------------------------------
output "private_app_subnet_ids" {
  description = "Map of private application subnet IDs (EKS tier)"
  value       = { for k, v in aws_subnet.private_app : k => v.id }
}

output "private_app_subnet_ids_list" {
  description = "List of private application subnet IDs – convenient for EKS node groups"
  value       = [for v in aws_subnet.private_app : v.id]
}

output "private_app_subnet_cidrs" {
  description = "Map of private application subnet CIDR blocks"
  value       = { for k, v in aws_subnet.private_app : k => v.cidr_block }
}

# ---------------------------------------------------------------------------
# Private Data Subnet outputs (RDS / ElastiCache)
# ---------------------------------------------------------------------------
output "private_data_subnet_ids" {
  description = "Map of private data subnet IDs (Database tier)"
  value       = { for k, v in aws_subnet.private_data : k => v.id }
}

output "private_data_subnet_ids_list" {
  description = "List of private data subnet IDs – convenient for DB subnet groups"
  value       = [for v in aws_subnet.private_data : v.id]
}

output "private_data_subnet_cidrs" {
  description = "Map of private data subnet CIDR blocks"
  value       = { for k, v in aws_subnet.private_data : k => v.cidr_block }
}

# ---------------------------------------------------------------------------
# NAT Gateway / EIP
# ---------------------------------------------------------------------------
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.nat.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway EIP"
  value       = aws_eip.nat.public_ip
}

# ---------------------------------------------------------------------------
# Route Tables
# ---------------------------------------------------------------------------
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the shared private route table"
  value       = aws_route_table.private.id
}
