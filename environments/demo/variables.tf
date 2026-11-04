variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "rusuh"
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
  description = "Create a NAT Gateway for private subnets (off by default: ~$30+/month; see modules/network/README.md)."
  type        = bool
  default     = false
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

variable "core_image" {
  description = "Container image for service-core. No default: from its CI build."
  type        = string
}

variable "queue_image" {
  description = "Container image for service-queue. No default: from its CI build."
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

variable "health_check_path" {
  description = "ALB health check path (assumption: confirm with service owners)."
  type        = string
  default     = "/"
}

variable "queue_path_patterns" {
  description = "ALB path patterns routed to the queue service."
  type        = list(string)
  default     = ["/api/queue/*"]
}

variable "db_password" {
  description = "Postgres master password. No default: supply via tfvars (gitignored), never commit."
  type        = string
  sensitive   = true
}

variable "core_secrets" {
  description = "service-core secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "queue_secrets" {
  description = "service-queue secrets: env var name -> Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "core_extra_environment" {
  description = "Extra env vars for service-core (merged over the standard ones)."
  type        = map(string)
  default     = {}
}

variable "queue_extra_environment" {
  description = "Extra env vars for service-queue (merged over the standard ones)."
  type        = map(string)
  default     = {}
}
