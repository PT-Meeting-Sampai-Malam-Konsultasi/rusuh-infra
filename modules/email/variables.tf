variable "project" {
  description = "Project name used in resource tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "domain" {
  description = "Sending domain for SES (identity + DKIM)."
  type        = string
  default     = "rusuh-tiket.web.id"
}
