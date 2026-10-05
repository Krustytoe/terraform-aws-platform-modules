output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "azs" {
  description = "Availability zones in use, index-aligned with the subnet outputs."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnet IDs, one per AZ."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs, one per AZ."
  value       = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  description = "Private route table IDs (for gateway VPC endpoints / TGW routes)."
  value       = aws_route_table.private[*].id
}

output "nat_gateway_public_ips" {
  description = "NAT egress IPs, for partner allow-lists."
  value       = aws_eip.nat[*].public_ip
}

output "flow_log_group_name" {
  description = "Flow log CloudWatch log group name, or null when disabled."
  value       = one(aws_cloudwatch_log_group.flow_logs[*].name)
}
