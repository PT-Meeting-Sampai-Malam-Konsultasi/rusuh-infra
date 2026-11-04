variable "project" {
  description = "Project name used in resource tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "api_domain" {
  description = "API subdomain for the ACM certificate (ALB-direct: certificate lives in the ALB region)."
  type        = string
  default     = "api.rusuh-tiket.web.id"
}
