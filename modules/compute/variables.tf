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

variable "core_port" {
  description = "Container port of service-core. No default: confirm with the service owner."
  type        = number
}

variable "queue_port" {
  description = "Container port of service-queue. No default: confirm with the service owner."
  type        = number
}

variable "core_cpu" {
  description = "Fargate CPU units for service-core."
  type        = number
  default     = 256
}

variable "core_memory" {
  description = "Fargate memory (MB) for service-core."
  type        = number
  default     = 512
}

variable "queue_cpu" {
  description = "Fargate CPU units for service-queue."
  type        = number
  default     = 256
}

variable "queue_memory" {
  description = "Fargate memory (MB) for service-queue."
  type        = number
  default     = 512
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

variable "health_check_path" {
  description = "ALB health check path. Default '/' is an assumption: confirm the real health endpoint with service owners before apply."
  type        = string
  default     = "/"
}

variable "queue_path_patterns" {
  description = "ALB listener path patterns routed to the queue service (Q41 module scheme: /api/queue/*)."
  type        = list(string)
  default     = ["/api/queue/*"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Empty = no HTTPS listener (HTTP only until the dns module certificate is validated)."
  type        = string
  default     = ""
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

variable "sqs_notification_queue_url" {
  description = "Notification SQS queue URL (from the messaging module). Empty = env var omitted."
  type        = string
  default     = ""
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
