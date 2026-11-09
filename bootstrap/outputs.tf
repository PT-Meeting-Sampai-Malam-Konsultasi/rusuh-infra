output "state_bucket_name" {
  description = "Pass this to environments as -backend-config=\"bucket=<value>\"."
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table_name" {
  description = "Pass this to environments as -backend-config=\"dynamodb_table=<value>\"."
  value       = aws_dynamodb_table.tflock.name
}
