# Module: dns

ACM + DNS records for `api.rusuh-tiket.web.id`.

Resources:

- `aws_acm_certificate` (DNS validation) for the api subdomain, in
  the same region as the ALB (ALB-direct direction).

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
- If the team ever chooses CloudFront in front of the API, the
  certificate must move to `us-east-1` (CloudFront requirement) —
  this module needs changing at that point.
- SSL does not exist at all right now — this module + the validation
  steps above close that gap.
