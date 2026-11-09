output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_address" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "valkey_primary_endpoint_address" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "valkey_port" {
  value = aws_elasticache_replication_group.this.port
}
