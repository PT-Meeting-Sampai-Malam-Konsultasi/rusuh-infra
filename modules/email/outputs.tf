output "identity_arn" {
  value = aws_sesv2_email_identity.domain.arn
}

output "dkim_tokens" {
  description = "Create these 3 CNAME records in Cloudflare to verify the domain and enable DKIM."
  value       = aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens
}
