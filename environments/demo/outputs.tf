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

output "certificate_arn" {
  value = module.dns.certificate_arn
}

output "certificate_validation_options" {
  value = module.dns.domain_validation_options
}

output "cloudfront_domain_name" {
  value = module.edge.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.edge.cloudfront_distribution_id
}

output "waf_acl_arn" {
  value = module.edge.waf_acl_arn
}

output "dashboard_name" {
  value = module.observability.dashboard_name
}
