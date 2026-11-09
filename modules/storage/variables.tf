variable "project" {
  description = "Project name used in resource tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for e-ticket PDFs. No default: bucket names are globally unique across all AWS accounts."
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects inside (false = protection; destroy fails while objects remain)."
  type        = bool
  default     = false
}
