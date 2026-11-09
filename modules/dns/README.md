# Module: dns

ACM + DNS records for `api.rusuh-tiket.web.id`.

Resources:

- `aws_acm_certificate` (DNS validation) for the api subdomain, in
  the same region as the ALB.

Manual steps (not possible via Terraform without a Cloudflare token,
written explicitly):

- Create the DNS records from the `domain_validation_options`
  output in Cloudflare — until those records exist, the certificate
  stays PENDING_VALIDATION and cannot be attached to the ALB
  listener.
- Once validated, fill the compute module's `certificate_arn` (via
  the demo environment) and apply again — the HTTPS 443 listener
  becomes active.
- Until then the demo runs on HTTP only (listener 80).
- The `api` record points at the CloudFront distribution domain
  (output `cloudfront_domain_name` from the demo environment), not
  directly at the ALB. Until the CloudFront custom domain is set up,
  the distribution has no custom domain — the `api` CNAME is the
  last step, after the us-east-1 certificate (below).
- SSL does not exist at all right now — this module + the validation
  steps above close that gap.

## CloudFront custom domain (separate certificate, us-east-1)

CloudFront requires its ACM certificate in us-east-1, so the
certificate in this module (ap-southeast-3, for the ALB) cannot be
reused for the CloudFront custom domain. A second certificate for
`api.rusuh-tiket.web.id` must be requested in us-east-1 (not in this
repo yet — TBD), validated via DNS in Cloudflare, then its ARN is
passed as `acm_certificate_arn_us_east_1` to the edge module. Until
then the edge module uses the CloudFront default domain.
