# Environment: demo

Evaluation environment for 13 November 2026. This root module wires
the modules in `../../modules/` into one applyable stack.

Status on this branch: all modules are wired (see `main.tf`):
`network`, `data`, `compute`, `messaging`, `email`, `storage`,
`secrets`, `dns`, `edge`, `observability`.

## Usage

1. Bootstrap first (see `../../bootstrap/README.md`), noting the state
   bucket name and lock table.
2. `terraform init` with `-backend-config` (see the root README).
3. `terraform plan` → review carefully → `terraform apply`.

## Required variables (no defaults)

`db_password`, `auth_image`, `core_image`, `payment_image`,
`notification_image`, `officer_image`, `admin_image`, `queue_image`,
`core_port`, `queue_port`, `s3_bucket_name` — supply via a tfvars
file (gitignored, never committed) or `-var`. Example:
`terraform plan -var-file="demo.tfvars"` with `demo.tfvars`
containing all eleven values. (Ports for auth/payment/notification/
officer/admin default to 8081/8083/8084/8085/8086.)

## Two-step flows (written explicitly, not assumed)

- Secrets: apply first (secrets are empty shells) → fill values via
  the AWS console/CLI by the owner → apply again with the secret ARNs
  in `auth_secrets`/`core_secrets`/`payment_secrets`/
  `notification_secrets`/`officer_secrets`/`admin_secrets`/
  `queue_secrets`.
- DNS/SES: after apply, create the validation records from the
  `certificate_validation_options` output and the email module's DKIM
  tokens in Cloudflare → certificate validated → fill
  `certificate_arn` and apply again to enable the HTTPS 443 listener.
  Until then the demo runs on HTTP only (and the HTTP listener
  forwards to core instead of redirecting to HTTPS).
- CloudFront custom domain: the edge module needs an ACM certificate
  for `api.rusuh-tiket.web.id` **in us-east-1** (separate from the
  ap-southeast-3 certificate in the dns module). Until
  `acm_certificate_arn_us_east_1` is set, the distribution has no
  custom domain — use the `cloudfront_domain_name` output. Once the
  us-east-1 certificate is validated, set the variable, re-apply,
  and point the `api` CNAME in Cloudflare at the CloudFront domain
  (see the edge module README).
- SES production access is a manual quota request (not Terraform) —
  arrange it before the evaluation.

## Assumptions to confirm before apply

- Images, ports, health check paths (queue/core `/readyz`, others
  `/health/live`), and standard env var names (see the compute module
  README) — confirm with the service-core and service-queue owners.
- The compute wiring assumes a `notification` queue exists in
  `var.queues` — if `queues` is overridden, keep `notification` or
  update the wiring.
- Demo topology: ECS tasks in public subnets with public IPs (NAT
  off). If NAT is enabled, change `ecs_subnet_ids` to private
  subnets and `assign_public_ip` to false.

Warning: `terraform destroy` in this environment deletes the entire
demo stack. Do not run it without team approval.
