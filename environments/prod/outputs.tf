output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "internet_gateway_id" {
  value = module.network.internet_gateway_id
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "db_master_user_secret_arn" {
  description = "ARN of the RDS-managed master credential secret."
  value       = module.data.db_master_user_secret_arn
}

output "db_endpoint" {
  value = module.data.db_endpoint
}

output "valkey_primary_endpoint_address" {
  value = module.data.valkey_primary_endpoint_address
}

output "notification_queue_url" {
  value = module.messaging.queue_urls["notification"]
}

output "s3_bucket_id" {
  value = module.storage.bucket_id
}

output "secret_arns" {
  value = module.secrets.secret_arns
}

output "cost_scheduler_role_arn" {
  description = "IAM role used by EventBridge Scheduler for cost-control actions."
  value       = module.cost_schedule.scheduler_role_arn
}

output "dashboard_name" {
  value = module.observability.dashboard_name
}
