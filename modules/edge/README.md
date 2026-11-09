# Edge Module

CloudFront distribution in front of the ALB + AWS WAFv2 Web ACL
(ADR-0012, ADR-0015). The API is reached at
`https://api.rusuh-tiket.web.id` through CloudFront, not directly at
the ALB.

## Resources

- `aws_cloudfront_distribution` — ALB origin, default behavior
  pass-through (no cache), ordered behavior for the queue frontier
  cached 1 second.
- `aws_wafv2_web_acl` (scope `CLOUDFRONT`, created in us-east-1) —
  rate-based rule + AWSManagedRulesCommonRuleSet, default allow.

## Cache behaviors

| Behavior | Cache | Notes |
| --- | --- | --- |
| Default (`*`) | none (TTL 0) | API pass-through: all methods, all cookies, Authorization/Host/Origin/Referer/Accept/Accept-Language/Content-Type forwarded. |
| `/v1/queue/*/frontier` | 1 s | Absorbs waiting-room polling (ADR-0015). No Authorization header forwarded, so the response is shared by all users of an event. |

Assumption: the frontier endpoint is public (no per-user auth). If
the queue app requires auth on the frontier, either forward the
Authorization header here (cache sharing is lost) or make the
endpoint public.

## WAF rules

- `rate-limit` (priority 10): block an IP that exceeds
  `waf_rate_limit` requests in 5 minutes (default 10000). Permissive
  starting point for a flash sale — many users may share one NAT IP.
  Tune after the load tests: lower if abuse is seen, raise if
  legitimate users are blocked.
- `aws-managed-common` (priority 20): AWSManagedRulesCommonRuleSet
  (SQL injection, XSS, bad bots, etc.). Default action allow.

## Origin protocol policy

Default `https-only`: CloudFront talks HTTPS to the ALB, which
requires the ALB HTTPS listener (compute module `certificate_arn`
set and validated). While the certificate is not yet validated, set
`origin_protocol_policy = "http-only"` so the distribution can be
created; switch to `https-only` once HTTPS on the ALB works.

## Custom domain — TBD

A CloudFront custom domain needs an ACM certificate **in us-east-1**
(CloudFront requirement). That certificate does not exist in this
repo yet. Until `acm_certificate_arn_us_east_1` is set, the
distribution has no aliases and uses the CloudFront default domain
(`<id>.cloudfront.net`).

Manual steps (Cloudflare, after the first apply):

1. Request an ACM certificate for `api.rusuh-tiket.web.id` in
   us-east-1 and validate it via DNS (add the validation CNAME in
   Cloudflare).
2. Set `acm_certificate_arn_us_east_1` in the environment and
   re-apply.
3. In Cloudflare, change the `api` record from the ALB DNS name to a
   CNAME pointing at the CloudFront domain name (output
   `cloudfront_domain_name`), DNS-only (not proxied — the edge is
   CloudFront, not Cloudflare).

## Dependencies

Needs `alb_dns_name` (compute module). The WAFv2 ACL is created with
the aliased provider `aws.us_east_1`; the environment must declare
that provider and pass it to this module:

```hcl
module "edge" {
  source = "../../modules/edge"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project       = var.project
  environment   = var.environment
  alb_dns_name  = module.compute.alb_dns_name
  api_domain    = var.api_domain
  waf_rate_limit = var.waf_rate_limit
}
```
