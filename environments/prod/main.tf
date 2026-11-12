module "network" {
  source = "../../modules/network"

  project              = var.project
  environment          = var.environment
  region               = var.region
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
  secrets = merge(var.secrets, {
    database-url = {
      description = "PostgreSQL URI consumed as DATABASE_URL by Node ECS tasks."
    }
  })
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
  # Derived from the ALB certificate, not a free variable: the ALB only
  # has an HTTPS listener when certificate_arn is set, so CloudFront must
  # use http-only until then (https-only with no listener = 502). When a
  # certificate is supplied the ALB gains the HTTPS listener and the
  # origin switches to https-only automatically.
  origin_protocol_policy = var.certificate_arn != "" ? "https-only" : "http-only"
  waf_rate_limit         = var.waf_rate_limit
  price_class            = var.edge_price_class
}

module "data" {
  source = "../../modules/data"

  project                           = var.project
  environment                       = var.environment
  vpc_id                            = module.network.vpc_id
  private_subnet_ids                = module.network.private_subnet_ids
  db_username                       = var.db_username
  master_user_secret_kms_key_id     = var.master_user_secret_kms_key_id
  valkey_transit_encryption_enabled = var.valkey_transit_encryption_enabled
  valkey_auth_token                 = var.valkey_auth_token
  alarm_actions                     = [module.observability.alarm_topic_arn]
}

module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment
  region      = var.region
  vpc_id      = module.network.vpc_id

  alb_subnet_ids = module.network.public_subnet_ids
  # Production topology: the ALB stays public, but the ECS tasks run in
  # private subnets with no public IP. Tasks reach the internet (ECR,
  # Midtrans, SES, SQS) through the per-AZ NAT gateways, and reach AWS
  # services privately through the VPC endpoints. A task is only reachable
  # through the ALB — never directly from the internet.
  ecs_subnet_ids   = module.network.private_subnet_ids
  assign_public_ip = false

  auth_image          = var.auth_image != "" ? var.auth_image : var.bootstrap_image
  core_image          = var.core_image != "" ? var.core_image : var.bootstrap_image
  payment_image       = var.payment_image != "" ? var.payment_image : var.bootstrap_image
  notification_image  = var.notification_image != "" ? var.notification_image : var.bootstrap_image
  officer_image       = var.officer_image != "" ? var.officer_image : var.bootstrap_image
  admin_image         = var.admin_image != "" ? var.admin_image : var.bootstrap_image
  queue_image         = var.queue_image != "" ? var.queue_image : var.bootstrap_image
  dukcapil_mock_image = var.dukcapil_mock_image != "" ? var.dukcapil_mock_image : var.bootstrap_image
  auth_port           = var.auth_port
  core_port           = var.core_port
  payment_port        = var.payment_port
  notification_port   = var.notification_port
  officer_port        = var.officer_port
  admin_port          = var.admin_port
  queue_port          = var.queue_port

  certificate_arn = var.certificate_arn

  core_desired_count          = var.core_desired_count
  queue_desired_count         = var.queue_desired_count
  autoscaling_min_capacity    = var.autoscaling_min_capacity
  dukcapil_mock_desired_count = var.dukcapil_mock_desired_count
  auth_desired_count          = var.auth_desired_count
  payment_desired_count       = var.payment_desired_count
  notification_desired_count  = var.notification_desired_count
  officer_desired_count       = var.officer_desired_count
  admin_desired_count         = var.admin_desired_count

  db_security_group_id     = module.data.db_security_group_id
  valkey_security_group_id = module.data.valkey_security_group_id
  database_url_secret_arn  = module.secrets.secret_arns["database-url-node"]
  db_address               = module.data.db_address
  db_port                  = module.data.db_port
  db_name                  = module.data.db_name
  valkey_host              = module.data.valkey_primary_endpoint_address
  valkey_port              = module.data.valkey_port
  # Same values the data module got above, so the cluster and the
  # connection URLs always agree (TLS scheme + auth token).
  valkey_transit_encryption_enabled = var.valkey_transit_encryption_enabled
  valkey_auth_token                 = var.valkey_auth_token

  sqs_queue_urls = {
    notification = module.messaging.queue_urls["notification"]
    otp          = module.messaging.queue_urls["otp"]
    empty_slot   = module.messaging.queue_urls["empty_slot"]
  }
  sqs_queue_arns            = values(module.messaging.queue_arns)
  s3_bucket_name            = module.storage.bucket_id
  s3_bucket_arn             = module.storage.bucket_arn
  ses_domain                = var.ses_domain
  ses_identity_arn          = module.email.identity_arn
  auth_secrets              = var.auth_secrets
  core_secrets              = var.core_secrets
  payment_secrets           = var.payment_secrets
  notification_secrets      = var.notification_secrets
  officer_secrets           = var.officer_secrets
  admin_secrets             = var.admin_secrets
  queue_secrets             = var.queue_secrets
  auth_extra_environment    = var.auth_extra_environment
  core_extra_environment    = var.core_extra_environment
  payment_extra_environment = var.payment_extra_environment
  officer_extra_environment = var.officer_extra_environment
  admin_extra_environment   = var.admin_extra_environment
  queue_extra_environment   = var.queue_extra_environment
}

module "cost_schedule" {
  source = "../../modules/cost-schedule"

  project                        = var.project
  environment                    = var.environment
  ecs_cluster_name               = module.compute.cluster_name
  db_instance_identifier         = module.data.db_instance_identifier
  weekday_service_desired_counts = var.weekday_service_desired_counts
  service_arns                   = module.compute.service_arns
  enabled                        = var.cost_schedule_enabled
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
  alarm_email        = var.alarm_email

  queue_log_group_name          = module.compute.queue_log_group_name
  queue_target_group_arn_suffix = module.compute.queue_target_group_arn_suffix
  # CloudTrail stays off: the account baseline trail (soldev-lz-trail,
  # multi-region) already covers audit. Enable only if this environment
  # needs its own trail in addition to the baseline.
  enable_cloudtrail = false
}
