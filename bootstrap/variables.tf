variable "project" {
  description = "Project name used in resource tags and the lock table name."
  type        = string
  default     = "msmk"
}

variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "ap-southeast-3"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state. Must be globally unique across all AWS accounts and start with msmk-."
  type        = string

  validation {
    condition     = startswith(var.state_bucket_name, "msmk-")
    error_message = "state_bucket_name must start with msmk-."
  }
}
