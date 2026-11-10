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

variable "db_name" {
  description = "Postgres database name."
  type        = string
  default     = "msmk"
}

variable "db_username" {
  description = "Postgres master username (not secret by itself; the password is)."
  type        = string
  default     = "msmk_app"
}

variable "master_user_secret_kms_key_id" {
  description = "Optional customer-managed KMS key ID or ARN for the RDS-managed master-user secret. Empty uses the AWS-managed Secrets Manager key."
  type        = string
  default     = ""
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
  description = "RDS Multi-AZ (production: synchronous standby in another AZ, automatic failover). Off only for a short-lived throwaway environment."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "RDS deletion protection (production: the database cannot be deleted accidentally; disable explicitly to tear down)."
  type        = bool
  default     = true
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
  description = "Number of Valkey cache clusters (2 = primary + replica with automatic failover; the queue relay uses WAIT 1, which needs a replica). Cost is 2x a single node."
  type        = number
  default     = 2
}

variable "valkey_transit_encryption_enabled" {
  description = "Valkey in-transit encryption. OFF by default: do not enable until the clients are verified TLS-compatible (rusuh-core must use a rediss:// VALKEY_URL, rusuh-queue (Go) must enable TLS in its Valkey client). Enabling it before the clients support TLS breaks their Valkey connections."
  type        = bool
  default     = false
}

variable "valkey_auth_token" {
  description = "Valkey AUTH token. Only set together with transit_encryption_enabled = true (AWS constraint)."
  type        = string
  sensitive   = true
  default     = null
}
