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

output "dashboard_name" {
  value = module.observability.dashboard_name
}
