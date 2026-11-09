module "network" {
  source = "../../modules/network"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
}

module "messaging" {
  source = "../../modules/messaging"

  project     = var.project
  environment = var.environment
  queues      = var.queues
}

module "email" {
  source = "../../modules/email"

  project     = var.project
  environment = var.environment
  domain      = var.ses_domain
}

module "storage" {
  source = "../../modules/storage"

  project     = var.project
  environment = var.environment
  bucket_name = var.s3_bucket_name
}

module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment
  secrets     = var.secrets
}

module "dns" {
  source = "../../modules/dns"

  project     = var.project
  environment = var.environment
  api_domain  = var.api_domain
}

module "edge" {
  source = "../../modules/edge"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project                       = var.project
  environment                   = var.environment
  alb_dns_name                  = module.compute.alb_dns_name
  api_domain                    = var.api_domain
  acm_certificate_arn_us_east_1 = var.acm_certificate_arn_us_east_1
  origin_protocol_policy        = var.edge_origin_protocol_policy
  waf_rate_limit                = var.waf_rate_limit
  price_class                   = var.edge_price_class
}

module "data" {
  source = "../../modules/data"

  project                = var.project
  environment            = var.environment
  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  ecs_security_group_ids = values(module.compute.ecs_security_group_ids)
  db_password            = var.db_password
}

module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment
  region      = var.region
  vpc_id      = module.network.vpc_id

  alb_subnet_ids = module.network.public_subnet_ids
  # Demo topology (NAT off): tasks in public subnets with public IPs.
  # If NAT is enabled later, switch to private subnets + assign_public_ip = false.
  ecs_subnet_ids   = module.network.public_subnet_ids
  assign_public_ip = true

  auth_image         = var.auth_image
  core_image         = var.core_image
  payment_image      = var.payment_image
  notification_image = var.notification_image
  officer_image      = var.officer_image
  admin_image        = var.admin_image
  queue_image        = var.queue_image
  auth_port          = var.auth_port
  core_port          = var.core_port
  payment_port       = var.payment_port
  notification_port  = var.notification_port
  officer_port       = var.officer_port
  admin_port         = var.admin_port
  queue_port         = var.queue_port

  certificate_arn = var.certificate_arn

  db_address  = module.data.db_address
  db_port     = module.data.db_port
  db_name     = module.data.db_name
  valkey_host = module.data.valkey_primary_endpoint_address
  valkey_port = module.data.valkey_port

  sqs_notification_queue_url = module.messaging.queue_urls["notification"]
  sqs_queue_arns             = values(module.messaging.queue_arns)
  s3_bucket_name             = module.storage.bucket_id
  s3_bucket_arn              = module.storage.bucket_arn
  ses_domain                 = var.ses_domain
  ses_identity_arn           = module.email.identity_arn
  auth_secrets               = var.auth_secrets
  core_secrets               = var.core_secrets
  payment_secrets            = var.payment_secrets
  notification_secrets       = var.notification_secrets
  officer_secrets            = var.officer_secrets
  admin_secrets              = var.admin_secrets
  queue_secrets              = var.queue_secrets
  auth_extra_environment     = var.auth_extra_environment
  core_extra_environment     = var.core_extra_environment
  payment_extra_environment  = var.payment_extra_environment
  officer_extra_environment  = var.officer_extra_environment
  admin_extra_environment    = var.admin_extra_environment
  queue_extra_environment    = var.queue_extra_environment
}

module "observability" {
  source = "../../modules/observability"

  project            = var.project
  environment        = var.environment
  region             = var.region
  alb_arn            = module.compute.alb_arn
  cluster_name       = module.compute.cluster_name
  core_service_name  = module.compute.core_service_name
  queue_service_name = module.compute.queue_service_name
  dlq_queue_arns     = module.messaging.dlq_arns
}
