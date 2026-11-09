variable "project" {
  description = "Project name used in resource tags and the lock table name."
  type        = string
  default     = "rusuh"
}

variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "ap-southeast-3"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state. Must be globally unique across all AWS accounts."
  type        = string
}
