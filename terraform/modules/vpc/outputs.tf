# VPC Outputs

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

# Subnet Outputs

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public Subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private Subnet IDs"
}

# Networking Outputs

output "internet_gateway_id" {
  value       = aws_internet_gateway.this.id
  description = "Internet Gateway ID"
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.this.id
  description = "NAT Gateway ID"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public Route Table ID"
}

output "private_route_table_ids" {
  value       = [aws_route_table.private.id]
  description = "Private Route Table IDs"
}
