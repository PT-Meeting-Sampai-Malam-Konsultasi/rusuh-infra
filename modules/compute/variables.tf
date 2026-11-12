variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "region" {
  description = "AWS region (used for CloudWatch log driver options)."
  type        = string
  default     = "ap-southeast-3"
}

variable "vpc_id" {
  description = "VPC ID (from the network module)."
  type        = string
}

variable "alb_subnet_ids" {
  description = "Public subnet IDs for the ALB (from the network module)."
  type        = list(string)
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for ECS tasks. Demo default: public subnets (NAT is off); see assign_public_ip."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IPs to ECS tasks (true for demo: NAT is off, tasks need outbound for image pull, SES, SQS)."
  type        = bool
  default     = true
}

variable "core_image" {
  description = "Container image for service-core (from its CI build). No default: supplied at apply time."
  type        = string
}

variable "queue_image" {
  description = "Container image for service-queue (from its CI build). No default: supplied at apply time."
  type        = string
}

variable "auth_image" {
  description = "Container image for service-auth (from its CI build). No default: supplied at apply time."
  type        = string
}

variable "payment_image" {
  description = "Container image for service-payment (from its CI build). No default: supplied at apply time."
  type        = string
}

variable "notification_image" {
  description = "Container image for service-notification (from its CI build). No default: supplied at apply time."
  type        = string
}

variable "officer_image" {
  description = "Container image for service-officer (from its CI build). No default: supplied at apply time."
  type        = string
}

variable "admin_image" {
  description = "Container image for service-admin (from its CI build). No default: supplied at apply time."
  type        = string
}

variable "core_port" {
  description = "Container port of service-core. No default: confirm with the service owner."
  type        = number
}

variable "queue_port" {
  description = "Container port of service-queue. No default: confirm with the service owner."
  type        = number
}

variable "auth_port" {
  description = "Container port of service-auth (rusuh-core app port 8081)."
  type        = number
  default     = 8081
}

variable "payment_port" {
  description = "Container port of service-payment (rusuh-core app port 8083)."
  type        = number
  default     = 8083
}

variable "notification_port" {
  description = "Container port of service-notification (rusuh-core app port 8084). Consumer-only: no ALB target group."
  type        = number
  default     = 8084
}

variable "officer_port" {
  description = "Container port of service-officer (rusuh-core app port 8085)."
  type        = number
  default     = 8085
}

variable "admin_port" {
  description = "Container port of service-admin (rusuh-core app port 8086)."
  type        = number
  default     = 8086
}

variable "core_cpu" {
  description = "Fargate CPU units for service-core (512 for the load tests)."
  type        = number
  default     = 512
}

variable "core_memory" {
  description = "Fargate memory (MB) for service-core (1024 for the load tests)."
  type        = number
  default     = 1024
}

variable "queue_cpu" {
  description = "Fargate CPU units for service-queue (512 for the load tests)."
  type        = number
  default     = 512
}

variable "queue_memory" {
  description = "Fargate memory (MB) for service-queue (1024 for the load tests)."
  type        = number
  default     = 1024
}

variable "auth_cpu" {
  description = "Fargate CPU units for service-auth."
  type        = number
  default     = 512
}

variable "auth_memory" {
  description = "Fargate memory (MB) for service-auth."
  type        = number
  default     = 1024
}

variable "dukcapil_mock_image" {
  description = "Container image for the Dukcapil NIV mock (rusuh-mock/service-dukcapil)."
  type        = string
  default     = "public.ecr.aws/docker/library/busybox:1.36.1"
}

variable "dukcapil_mock_port" {
  description = "Container port of the Dukcapil mock (EXPOSE 8080 in its Dockerfile)."
  type        = number
  default     = 8080
}

variable "dukcapil_mock_cpu" {
  description = "Fargate CPU units for the Dukcapil mock (stateless Express app)."
  type        = number
  default     = 256
}

variable "dukcapil_mock_memory" {
  description = "Fargate memory (MB) for the Dukcapil mock."
  type        = number
  default     = 512
}

variable "dukcapil_mock_desired_count" {
  description = "Initial ECS desired count for the Dukcapil mock."
  type        = number
  default     = 0
}

variable "payment_cpu" {
  description = "Fargate CPU units for service-payment."
  type        = number
  default     = 512
}

variable "payment_memory" {
  description = "Fargate memory (MB) for service-payment."
  type        = number
  default     = 1024
}

variable "notification_cpu" {
  description = "Fargate CPU units for service-notification."
  type        = number
  default     = 512
}

variable "notification_memory" {
  description = "Fargate memory (MB) for service-notification."
  type        = number
  default     = 1024
}

variable "officer_cpu" {
  description = "Fargate CPU units for service-officer."
  type        = number
  default     = 512
}

variable "officer_memory" {
  description = "Fargate memory (MB) for service-officer."
  type        = number
  default     = 1024
}

variable "admin_cpu" {
  description = "Fargate CPU units for service-admin."
  type        = number
  default     = 512
}

variable "admin_memory" {
  description = "Fargate memory (MB) for service-admin."
  type        = number
  default     = 1024
}

variable "core_desired_count" {
  description = "Desired task count for service-core."
  type        = number
  default     = 1
}

variable "queue_desired_count" {
  description = "Desired task count for service-queue."
  type        = number
  default     = 1
}

variable "auth_desired_count" {
  description = "Desired task count for service-auth."
  type        = number
  default     = 1
}

variable "payment_desired_count" {
  description = "Desired task count for service-payment."
  type        = number
  default     = 1
}

variable "notification_desired_count" {
  description = "Desired task count for service-notification."
  type        = number
  default     = 1
}

variable "officer_desired_count" {
  description = "Desired task count for service-officer."
  type        = number
  default     = 1
}

variable "admin_desired_count" {
  description = "Desired task count for service-admin."
  type        = number
  default     = 1
}

variable "queue_health_check_path" {
  description = "ALB health check path for service-queue (/readyz answers 503 while a task drains on SIGTERM, which is intended)."
  type        = string
  default     = "/readyz"
}

variable "core_health_check_path" {
  description = "ALB health check path for service-core (/readyz, same as queue; core exposes it alongside /health/live)."
  type        = string
  default     = "/readyz"
}

variable "auth_health_check_path" {
  description = "ALB health check path for service-auth."
  type        = string
  default     = "/health/live"
}

variable "payment_health_check_path" {
  description = "ALB health check path for service-payment."
  type        = string
  default     = "/health/live"
}

variable "notification_health_check_path" {
  description = "Health check path for service-notification (not used by an ALB target group: the service is consumer-only)."
  type        = string
  default     = "/health/live"
}

variable "officer_health_check_path" {
  description = "ALB health check path for service-officer."
  type        = string
  default     = "/health/live"
}

variable "admin_health_check_path" {
  description = "ALB health check path for service-admin."
  type        = string
  default     = "/health/live"
}

variable "queue_path_patterns" {
  description = "ALB listener path patterns routed to the queue service (per-service routing, ADR-0017 /v1/ prefix)."
  type        = list(string)
  default     = ["/v1/queue/*"]
}

variable "core_path_patterns" {
  description = "ALB listener path patterns routed to the core service (per-service routing, ADR-0017 /v1/ prefix). /v1/core/admission is blocked from the public listeners by the internal-path rule."
  type        = list(string)
  default     = ["/v1/core/*"]
}

variable "auth_path_patterns" {
  description = "ALB listener path patterns routed to the auth service (per-service routing, ADR-0017 /v1/ prefix)."
  type        = list(string)
  default     = ["/v1/auth/*"]
}

variable "payment_path_patterns" {
  description = "ALB listener path patterns routed to the payment service (per-service routing, ADR-0017 /v1/ prefix)."
  type        = list(string)
  default     = ["/v1/payment/*"]
}

variable "officer_path_patterns" {
  description = "ALB listener path patterns routed to the officer service (per-service routing, ADR-0017 /v1/ prefix)."
  type        = list(string)
  default     = ["/v1/officer/*"]
}

variable "admin_path_patterns" {
  description = "ALB listener path patterns routed to the admin service (per-service routing, ADR-0017 /v1/ prefix)."
  type        = list(string)
  default     = ["/v1/admin/*"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Empty = no HTTPS listener (HTTP only until the dns module certificate is validated)."
  type        = string
  default     = ""
}

variable "db_security_group_id" {
  description = "Security group ID of Postgres (from the data module). The compute module creates the ingress rules on it, so the data module never needs the ECS security groups."
  type        = string
  default     = ""
}

variable "valkey_security_group_id" {
  description = "Security group ID of Valkey (from the data module). The compute module creates the ingress rules on it."
  type        = string
  default     = ""
}

variable "database_url_secret_arn" {
  description = "Secrets Manager ARN containing the DATABASE_URL value injected into Node ECS task definitions."
  type        = string
}

variable "valkey_transit_encryption_enabled" {
  description = "Whether Valkey uses in-transit encryption (must match the data module). Chooses rediss:// vs redis:// for VALKEY_URL."
  type        = bool
  default     = false
}

variable "valkey_auth_token" {
  description = "Valkey AUTH token (must match the data module's valkey_auth_token). Only set together with transit encryption (AWS constraint). Embedded in VALKEY_URL / passed as VALKEY_PASSWORD to the queue."
  type        = string
  sensitive   = true
  default     = null
}

variable "db_address" {
  description = "Postgres host (from the data module)."
  type        = string
}

variable "db_port" {
  description = "Postgres port (from the data module)."
  type        = number
}

variable "db_name" {
  description = "Postgres database name (from the data module)."
  type        = string
}

variable "valkey_host" {
  description = "Valkey primary endpoint host (from the data module)."
  type        = string
}

variable "valkey_port" {
  description = "Valkey port (from the data module)."
  type        = number
}

variable "sqs_queue_urls" {
  description = "SQS queue URLs by logical name (notification, otp, empty_slot) from the messaging module. Env vars are injected only for names present here."
  type        = map(string)
  default     = {}
}

variable "sqs_queue_arns" {
  description = "SQS queue ARNs the task role may use (from the messaging module). Empty = no SQS statement."
  type        = list(string)
  default     = []
}

variable "s3_bucket_name" {
  description = "E-ticket S3 bucket name (from the storage module). Empty = env var omitted."
  type        = string
  default     = ""
}

variable "s3_bucket_arn" {
  description = "E-ticket S3 bucket ARN (from the storage module). Empty = no S3 statement."
  type        = string
  default     = ""
}

variable "ses_domain" {
  description = "SES sending domain (from the email module). Empty = env var omitted."
  type        = string
  default     = ""
}

variable "ses_identity_arn" {
  description = "SES identity ARN (from the email module). Empty = no SES statement."
  type        = string
  default     = ""
}

variable "core_secrets" {
  description = "service-core secrets: map of env var name -> Secrets Manager ARN (from the secrets module). Empty = none injected."
  type        = map(string)
  default     = {}
}

variable "queue_secrets" {
  description = "service-queue secrets: map of env var name -> Secrets Manager ARN (from the secrets module). Empty = none injected."
  type        = map(string)
  default     = {}
}

variable "auth_secrets" {
  description = "service-auth secrets: map of env var name -> Secrets Manager ARN (from the secrets module). Empty = none injected."
  type        = map(string)
  default     = {}
}

variable "payment_secrets" {
  description = "service-payment secrets: map of env var name -> Secrets Manager ARN (from the secrets module). Empty = none injected."
  type        = map(string)
  default     = {}
}

variable "notification_secrets" {
  description = "service-notification secrets: map of env var name -> Secrets Manager ARN (from the secrets module). Empty = none injected."
  type        = map(string)
  default     = {}
}

variable "officer_secrets" {
  description = "service-officer secrets: map of env var name -> Secrets Manager ARN (from the secrets module). Empty = none injected."
  type        = map(string)
  default     = {}
}

variable "admin_secrets" {
  description = "service-admin secrets: map of env var name -> Secrets Manager ARN (from the secrets module). Empty = none injected."
  type        = map(string)
  default     = {}
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN used to encrypt Secrets Manager secrets. Empty = AWS-managed key, no kms:Decrypt statement on the execution role."
  type        = string
  default     = ""
}

variable "core_extra_environment" {
  description = "Extra env vars for service-core (merged over the standard ones, so owners can add/override without touching the module)."
  type        = map(string)
  default     = {}
}

variable "queue_extra_environment" {
  description = "Extra env vars for service-queue (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "auth_extra_environment" {
  description = "Extra env vars for service-auth (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "payment_extra_environment" {
  description = "Extra env vars for service-payment (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "notification_extra_environment" {
  description = "Extra env vars for service-notification (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "officer_extra_environment" {
  description = "Extra env vars for service-officer (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "admin_extra_environment" {
  description = "Extra env vars for service-admin (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention for ECS log groups."
  type        = number
  default     = 14
}

variable "container_insights_enabled" {
  description = "ECS Container Insights (useful during the one-shot evaluation)."
  type        = bool
  default     = true
}

variable "service_connect_namespace" {
  description = "Cloud Map HTTP namespace for ECS Service Connect (private service-to-service calls, e.g. core.msmk.local)."
  type        = string
  default     = "msmk.local"
}

variable "cors_origins" {
  description = "Browser origins allowed to call the APIs. Injected as CORS_ORIGINS (comma-separated) into every service: the six Node services and the Go queue read the same variable. An empty list injects nothing, so each service falls back to its own built-in default."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for o in var.cors_origins : can(regex("^https?://[^/\\s]+$", o))])
    error_message = "Each cors_origins entry must be an origin: http(s)://host[:port], with no path and no trailing slash."
  }
}

variable "autoscaling_min_capacity" {
  description = "Autoscaling minimum task count per ALB-backed service."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Autoscaling maximum task count per ALB-backed service (tune after the load tests)."
  type        = number
  default     = 3
}

variable "autoscaling_cpu_target" {
  description = "Autoscaling target tracking CPU utilization percent per ALB-backed service."
  type        = number
  default     = 70
}
