variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "msmk"
}

variable "environment" {
  description = "Environment name used in resource names and tags (prod = production environment for the 13 Nov 2026 evaluation and beyond)."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region for all resources in this environment."
  type        = string
  default     = "ap-southeast-3"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across (2 AZs)."
  type        = list(string)
  default     = ["ap-southeast-3a", "ap-southeast-3b"]
}

variable "public_subnet_cidrs" {
  description = "One CIDR per availability zone, for public subnets (ALB only)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "One CIDR per availability zone, for private subnets (data)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway per AZ for private subnets (production: on). ~$32/month per gateway plus data processing. Off only for a short-lived throwaway environment."
  type        = bool
  default     = true
}

variable "queues" {
  description = "Queues for the messaging module. Topology: otp (auth -> notification), notification (core -> notification), empty_slot (core -> queue service)."
  type = map(object({
    visibility_timeout_seconds = optional(number, 300)
    message_retention_seconds  = optional(number, 1209600)
    max_receive_count          = optional(number, 5)
  }))
  default = {
    notification = {}
    otp          = {}
    empty_slot   = {}
  }
}

variable "ses_domain" {
  description = "SES sending domain."
  type        = string
  default     = "rusuh-tiket.web.id"
}

variable "cors_origins" {
  description = "Single source of truth for the browser origins allowed by CORS. Injected as CORS_ORIGINS into all services (auth, core, payment, notification, officer, admin, queue). The default matches the allowlist the Node services shipped with, so enabling this variable changes no behaviour; edit it here to change every service at once."
  type        = list(string)
  default = [
    "https://rusuh-tiket.web.id",
    "https://www.rusuh-tiket.web.id",
    "http://localhost:3000",
    "http://localhost:5173",
  ]
}

variable "s3_bucket_name" {
  description = "S3 bucket name for e-ticket PDFs. Must be globally unique and start with msmk-."
  type        = string

  validation {
    condition     = startswith(var.s3_bucket_name, "msmk-")
    error_message = "s3_bucket_name must start with msmk-."
  }
}

variable "secrets" {
  description = "Secret shells for the secrets module (values are never set here)."
  type = map(object({
    description = optional(string, "")
  }))
  default = {}
}

variable "api_domain" {
  description = "API subdomain for the ACM certificate."
  type        = string
  default     = "api.rusuh-tiket.web.id"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the compute HTTPS listener. Empty = HTTP only until the dns certificate is validated."
  type        = string
  default     = ""
}

variable "bootstrap_image" {
  description = "Valid public image used by zero-count ECS task definitions until service images are published."
  type        = string
  default     = "public.ecr.aws/docker/library/busybox:1.36.1"
}

variable "auth_image" {
  description = "Container image for service-auth. Empty uses bootstrap_image while desired count is zero."
  type        = string
  default     = ""
}

variable "core_image" {
  description = "Container image for service-core. Empty uses bootstrap_image while desired count is zero."
  type        = string
  default     = ""
}

variable "payment_image" {
  description = "Container image for service-payment. Empty uses bootstrap_image while desired count is zero."
  type        = string
  default     = ""
}

variable "notification_image" {
  description = "Container image for service-notification. Empty uses bootstrap_image while desired count is zero."
  type        = string
  default     = ""
}

variable "officer_image" {
  description = "Container image for service-officer. Empty uses bootstrap_image while desired count is zero."
  type        = string
  default     = ""
}

variable "admin_image" {
  description = "Container image for service-admin. Empty uses bootstrap_image while desired count is zero."
  type        = string
  default     = ""
}

variable "queue_image" {
  description = "Container image for service-queue. Empty uses bootstrap_image while desired count is zero."
  type        = string
  default     = ""
}

variable "dukcapil_mock_image" {
  description = "Container image for the Dukcapil NIK-verification mock (rusuh-mock/service-dukcapil). Empty uses bootstrap_image."
  type        = string
  default     = ""
}

variable "dukcapil_mock_desired_count" {
  description = "Initial ECS desired count for the Dukcapil mock."
  type        = number
  default     = 0
}

variable "auth_port" {
  description = "Container port of service-auth."
  type        = number
  default     = 8081
}

variable "core_port" {
  description = "Container port of service-core. Bootstrap default is 8080; override with the verified service port before enabling ECS schedules."
  type        = number
  default     = 8080
}

variable "payment_port" {
  description = "Container port of service-payment."
  type        = number
  default     = 8083
}

variable "notification_port" {
  description = "Container port of service-notification."
  type        = number
  default     = 8084
}

variable "officer_port" {
  description = "Container port of service-officer."
  type        = number
  default     = 8085
}

variable "admin_port" {
  description = "Container port of service-admin."
  type        = number
  default     = 8086
}

variable "queue_port" {
  description = "Container port of service-queue. Bootstrap default is 8080; override with the verified service port before enabling ECS schedules."
  type        = number
  default     = 8080
}

variable "core_desired_count" {
  description = "Initial ECS desired count for service-core. Keep 0 until runtime images and secrets are ready."
  type        = number
  default     = 0
}

variable "queue_desired_count" {
  description = "Initial ECS desired count for service-queue. Keep 0 until Valkey client compatibility is verified."
  type        = number
  default     = 0
}

variable "auth_desired_count" {
  description = "Initial ECS desired count for service-auth. Keep 0 until runtime images and secrets are ready."
  type        = number
  default     = 0
}

variable "payment_desired_count" {
  description = "Initial ECS desired count for service-payment. Keep 0 until runtime images and secrets are ready."
  type        = number
  default     = 0
}

variable "notification_desired_count" {
  description = "Initial ECS desired count for service-notification. Keep 0 until runtime images and secrets are ready."
  type        = number
  default     = 0
}

variable "officer_desired_count" {
  description = "Initial ECS desired count for service-officer. Keep 0 until runtime images and secrets are ready."
  type        = number
  default     = 0
}

variable "admin_desired_count" {
  description = "Initial ECS desired count for service-admin. Keep 0 until runtime images and secrets are ready."
  type        = number
  default     = 0
}

variable "autoscaling_min_capacity" {
  description = "Minimum ECS desired count. Keep 0 until service images and runtime secrets are verified."
  type        = number
  default     = 0
}

variable "weekday_service_desired_counts" {
  description = "ECS service desired counts set at 06:00 WIB on weekdays by the cost scheduler. Keys must match compute.service_arns."
  type        = map(number)
  default = {
    auth          = 1
    core          = 1
    payment       = 1
    notification  = 1
    officer       = 1
    admin         = 1
    queue         = 1
    dukcapil-mock = 1
  }
}

variable "cost_schedule_enabled" {
  description = "Enable EventBridge Scheduler after service images, DATABASE_URL, and runtime checks are ready."
  type        = bool
  default     = false
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN for the API domain in us-east-1 (CloudFront custom domain). Empty = no custom domain on CloudFront yet."
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address that receives CloudWatch alarm notifications via SNS. Required (no default): enterprise readiness needs a mandatory alert endpoint. The recipient must confirm the SNS subscription after apply."
  type        = string
}

variable "waf_rate_limit" {
  description = "WAF rate-based rule: max requests per 5 minutes per IP."
  type        = number
  default     = 10000
}

variable "edge_price_class" {
  description = "CloudFront price class (PriceClass_200 includes Asia)."
  type        = string
  default     = "PriceClass_200"
}

variable "db_username" {
  description = "Postgres master username. Passed to both the data module (creates the user) and the compute module (builds DATABASE_URL), so they always agree."
  type        = string
  default     = "msmk_app"
}

variable "master_user_secret_kms_key_id" {
  description = "Optional customer-managed KMS key ID or ARN for the RDS-managed master-user secret. Empty uses the AWS-managed Secrets Manager key."
  type        = string
  default     = ""
}

variable "valkey_transit_encryption_enabled" {
  description = "Valkey in-transit encryption. OFF by default until the clients are verified TLS-compatible. Passed to both the data module (creates the cluster) and the compute module (chooses rediss:// vs redis:// for VALKEY_URL), so they always agree."
  type        = bool
  default     = false
}

variable "valkey_auth_token" {
  description = "Valkey AUTH token. Only set together with valkey_transit_encryption_enabled = true (AWS constraint). Passed to both the data module (sets the cluster token) and the compute module (embeds it in VALKEY_URL / VALKEY_PASSWORD), so they always agree."
  type        = string
  sensitive   = true
  default     = null
}

variable "auth_secrets" {
  description = "service-auth secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "core_secrets" {
  description = "service-core secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "payment_secrets" {
  description = "service-payment secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "notification_secrets" {
  description = "service-notification secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "officer_secrets" {
  description = "service-officer secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "admin_secrets" {
  description = "service-admin secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "queue_secrets" {
  description = "service-queue secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "auth_extra_environment" {
  description = "Extra env vars for service-auth (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "core_extra_environment" {
  description = "Extra env vars for service-core (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "payment_extra_environment" {
  description = "Extra env vars for service-payment (merged over the standard ones)."
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

variable "queue_extra_environment" {
  description = "Extra env vars for service-queue (merged over the standard ones)."
  type        = map(string)
  default     = {}
}
