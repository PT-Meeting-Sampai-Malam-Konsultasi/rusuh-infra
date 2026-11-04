variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (from the network module)."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS and Valkey (from the network module)."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group of ECS tasks; the only group allowed to reach Postgres and Valkey (from the compute module)."
  type        = string
}

variable "db_name" {
  description = "Postgres database name."
  type        = string
  default     = "rusuh"
}

variable "db_username" {
  description = "Postgres master username (not secret by itself; the password is)."
  type        = string
  default     = "rusuh_app"
}

variable "db_password" {
  description = "Postgres master password. No default: supply via tfvars (gitignored) or out-of-band; never commit it."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class (demo-sized default)."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Postgres major version (AWS picks the latest minor)."
  type        = string
  default     = "16"
}

variable "db_backup_retention_period" {
  description = "RDS automated backup retention in days."
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "RDS Multi-AZ (off for demo cost; enable for production hardening)."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "RDS deletion protection (off for demo iteration; enable for production)."
  type        = bool
  default     = false
}

variable "valkey_node_type" {
  description = "ElastiCache node type (demo-sized default)."
  type        = string
  default     = "cache.t4g.micro"
}

variable "valkey_engine_version" {
  description = "Valkey engine version."
  type        = string
  default     = "7.2"
}

variable "valkey_num_cache_clusters" {
  description = "Number of Valkey cache clusters (1 = single node, no failover; demo default)."
  type        = number
  default     = 1
}

variable "valkey_transit_encryption_enabled" {
  description = "Valkey in-transit encryption (off for demo; requires client TLS when on)."
  type        = bool
  default     = false
}

variable "valkey_auth_token" {
  description = "Valkey AUTH token. Only set together with transit_encryption_enabled = true (AWS constraint)."
  type        = string
  sensitive   = true
  default     = null
}
