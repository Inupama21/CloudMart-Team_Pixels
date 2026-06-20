output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private application subnet IDs"
  value       = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  description = "Isolated data subnet IDs"
  value       = aws_subnet.data[*].id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "eks_node_security_group_id" {
  description = "Supplemental EKS worker-node security group ID"
  value       = aws_security_group.eks_nodes.id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "private_route_table_ids" {
  description = "Application route table IDs"
  value       = aws_route_table.private[*].id
}

output "data_route_table_id" {
  description = "Isolated data route table ID"
  value       = aws_route_table.data.id
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB gateway endpoint ID"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "secretsmanager_endpoint_id" {
  description = "Secrets Manager interface endpoint ID"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "flow_log_group_name" {
  description = "CloudWatch log group receiving VPC flow logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "bastion_instance_id" {
  description = "SSM-managed bastion instance ID"
  value       = var.enable_bastion ? aws_instance.bastion[0].id : null
}

output "bastion_security_group_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion.id
}
