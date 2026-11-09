variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "region" {
  description = "AWS region (used for dashboard widgets)."
  type        = string
  default     = "ap-southeast-3"
}

variable "alb_arn" {
  description = "ALB ARN (from the compute module; the LoadBalancer dimension is derived from it)."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name (from the compute module)."
  type        = string
}

variable "core_service_name" {
  description = "ECS service name for service-core (from the compute module)."
  type        = string
}

variable "queue_service_name" {
  description = "ECS service name for service-queue (from the compute module)."
  type        = string
}

variable "dlq_queue_arns" {
  description = "DLQ ARNs to alarm and chart (from the messaging module). Empty = no DLQ alarm/widget."
  type        = map(string)
  default     = {}
}

variable "alarm_5xx_threshold" {
  description = "ALB target 5xx count threshold per period."
  type        = number
  default     = 10
}

variable "alarm_5xx_period" {
  description = "ALB 5xx alarm period in seconds."
  type        = number
  default     = 300
}

variable "alarm_5xx_evaluation_periods" {
  description = "ALB 5xx alarm evaluation periods."
  type        = number
  default     = 1
}

variable "dashboard_name" {
  description = "CloudWatch dashboard name. Empty = <project>-<environment>-overview."
  type        = string
  default     = ""
}
