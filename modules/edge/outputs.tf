output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (CNAME api.rusuh-tiket.web.id to this in Cloudflare)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.this.arn
}

output "waf_acl_id" {
  value = aws_wafv2_web_acl.this.id
}
