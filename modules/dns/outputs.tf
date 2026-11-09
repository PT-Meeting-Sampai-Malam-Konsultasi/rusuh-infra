output "certificate_arn" {
  value = aws_acm_certificate.api.arn
}

output "domain_validation_options" {
  description = "Create these DNS records in Cloudflare to validate the certificate (name, type, value per domain)."
  value       = aws_acm_certificate.api.domain_validation_options
}
