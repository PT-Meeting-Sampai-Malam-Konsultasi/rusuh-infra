variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name (from the compute module); the CloudFront origin."
  type        = string
}

variable "api_domain" {
  description = "API domain served through CloudFront (CNAME in Cloudflare points here)."
  type        = string
  default     = "api.rusuh-tiket.web.id"
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN for the API domain in us-east-1 (CloudFront requirement). Empty = no custom domain: the distribution uses the CloudFront default domain and no aliases. The certificate must be created in us-east-1 first (TBD: not in this repo yet)."
  type        = string
  default     = ""
}

variable "origin_protocol_policy" {
  description = "Protocol CloudFront uses to the ALB origin. Must match the ALB listener: https-only only when the ALB has an HTTPS listener (compute certificate_arn set); http-only while the ALB is HTTP-only. The demo root derives this from certificate_arn so it can never be inconsistent."
  type        = string
  default     = "http-only"

  validation {
    condition     = contains(["http-only", "https-only", "match-viewer"], var.origin_protocol_policy)
    error_message = "origin_protocol_policy must be http-only, https-only, or match-viewer."
  }
}

variable "waf_rate_limit" {
  description = "WAF rate-based rule: max requests per 5 minutes per IP. Permissive starting point for a flash sale (many users may share one NAT IP); tune down after the load tests if abuse is seen, up if legitimate users are blocked."
  type        = number
  default     = 10000
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_200 includes Asia (users are in Indonesia); PriceClass_100 would exclude it."
  type        = string
  default     = "PriceClass_200"
}
