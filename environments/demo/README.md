# Environment: demo

Evaluation environment for 13 November 2026. This root module wires
the modules in `../../modules/` into one applyable stack.

Status on this branch: all modules are wired (see `main.tf`):
`network`, `data`, `compute`, `messaging`, `email`, `storage`,
`secrets`, `dns`, `observability`.

## Usage

1. Bootstrap first (see `../../bootstrap/README.md`), noting the state
   bucket name and lock table.
2. `terraform init` with `-backend-config` (see the root README).
3. `terraform plan` → review carefully → `terraform apply`.

## Required variables (no defaults)

`db_password`, `core_image`, `queue_image`, `core_port`, `queue_port`,
`s3_bucket_name` — supply via a tfvars file (gitignored, never
committed) or `-var`. Example: `terraform plan
-var-file="demo.tfvars"` with `demo.tfvars` containing all six values.

## Two-step flows (written explicitly, not assumed)

- Secrets: apply first (secrets are empty shells) → fill values via
  the AWS console/CLI by the owner → apply again with the secret ARNs
  in `core_secrets`/`queue_secrets`.
- DNS/SES: after apply, create the validation records from the
  `certificate_validation_options` output and the email module's DKIM
  tokens in Cloudflare → certificate validated → fill
  `certificate_arn` and apply again to enable the HTTPS 443 listener.
  Until then the demo runs on HTTP only.
- SES production access is a manual quota request (not Terraform) —
  arrange it before the evaluation.

## Assumptions to confirm before apply

- Images, ports, health check path (`/`), and standard env var names
  (see the compute module README) — confirm with the service-core
  and service-queue owners.
- The compute wiring assumes a `notification` queue exists in
  `var.queues` — if `queues` is overridden, keep `notification` or
  update the wiring.
- Demo topology: ECS tasks in public subnets with public IPs (NAT
  off). If NAT is enabled, change `ecs_subnet_ids` to private
  subnets and `assign_public_ip` to false.

Warning: `terraform destroy` in this environment deletes the entire
demo stack. Do not run it without team approval.
