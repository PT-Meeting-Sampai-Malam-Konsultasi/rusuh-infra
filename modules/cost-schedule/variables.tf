variable "project" {
  description = "Project prefix used in scheduler resource names."
  type        = string
}

variable "environment" {
  description = "Environment name used in scheduler resource names."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster whose services the schedules scale."
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS instance identifier started and stopped by the schedules."
  type        = string
}

variable "weekday_service_desired_counts" {
  description = "ECS service names mapped to desired counts used from 06:00 WIB on weekdays."
  type        = map(number)
}

variable "service_arns" {
  description = "ECS service ARNs allowed to be scaled by EventBridge Scheduler."
  type        = map(string)
}

variable "enabled" {
  description = "Whether cost schedules are enabled."
  type        = bool
  default     = true
}
