output "db_security_group_id" {
  description = "Security group ID of Postgres. The compute module creates the ingress rules on it (which ECS tasks may connect)."
  value       = aws_security_group.db.id
}

output "valkey_security_group_id" {
  description = "Security group ID of Valkey. The compute module creates the ingress rules on it."
  value       = aws_security_group.valkey.id
}

output "db_master_user_secret_arn" {
  description = "ARN of the RDS-managed secret containing the PostgreSQL master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "db_instance_identifier" {
  description = "RDS instance identifier used by operational schedules."
  value       = aws_db_instance.this.identifier
}

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
  value = 6379
}
