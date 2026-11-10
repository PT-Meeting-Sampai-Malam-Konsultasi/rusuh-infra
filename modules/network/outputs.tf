output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "First NAT gateway ID (backwards compatible). Null when enable_nat_gateway is false."
  value       = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs, one per availability zone. Empty when enable_nat_gateway is false."
  value       = aws_nat_gateway.this[*].id
}
