variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "msmk"
}

variable "environment" {
  description = "Environment name (demo = evaluation environment for 13 Nov 2026)."
  type        = string
  default     = "demo"
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
  description = "Availability zones to spread subnets across (2 AZs for demo)."
  type        = list(string)
  default     = ["ap-southeast-3a", "ap-southeast-3b"]
}

variable "public_subnet_cidrs" {
  description = "One CIDR per availability zone, for public subnets (ALB + demo ECS)."
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
  description = "Queues for the messaging module (default includes notification; the compute wiring assumes a 'notification' queue exists — keep it when overriding)."
  type = map(object({
    visibility_timeout_seconds = optional(number, 300)
    message_retention_seconds  = optional(number, 1209600)
    max_receive_count          = optional(number, 5)
  }))
  default = {
    notification = {}
  }
}

variable "ses_domain" {
  description = "SES sending domain."
  type        = string
  default     = "rusuh-tiket.web.id"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for e-ticket PDFs. No default: globally unique."
  type        = string
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

variable "auth_image" {
  description = "Container image for service-auth. No default: from its CI build."
  type        = string
}

variable "core_image" {
  description = "Container image for service-core. No default: from its CI build."
  type        = string
}

variable "payment_image" {
  description = "Container image for service-payment. No default: from its CI build."
  type        = string
}

variable "notification_image" {
  description = "Container image for service-notification. No default: from its CI build."
  type        = string
}

variable "officer_image" {
  description = "Container image for service-officer. No default: from its CI build."
  type        = string
}

variable "admin_image" {
  description = "Container image for service-admin. No default: from its CI build."
  type        = string
}

variable "queue_image" {
  description = "Container image for service-queue. No default: from its CI build."
  type        = string
}

variable "auth_port" {
  description = "Container port of service-auth."
  type        = number
  default     = 8081
}

variable "core_port" {
  description = "Container port of service-core. No default: confirm with the service owner."
  type        = number
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
  description = "Container port of service-queue. No default: confirm with the service owner."
  type        = number
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

variable "db_password" {
  description = "Postgres master password. No default: supply via tfvars (gitignored), never commit."
  type        = string
  sensitive   = true
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
