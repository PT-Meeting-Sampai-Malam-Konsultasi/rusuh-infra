# rusuh-infra

Infrastructure-as-code for rusuh (ticket booking): all environments
are defined with Terraform in this repo, separate from the application
repos (`rusuh-core`, `rusuh-queue`, `rusuh-mock`) and the documentation
repo (`rusuh-documentation`).

Platform: AWS Jakarta region (`ap-southeast-3`) — per ADR-0012 in the
documentation repo. Terraform `>= 1.5`, AWS provider `~> 5.0`.

## Architecture (summary)

- Web: Cloudflare Pages (FE team, Wrangler).
- API: ALB → ECS (service-core Node.js + service-queue Go). CloudFront
  in front of the API is optional (team decision still open); the
  ALB-direct path applies until decided otherwise.
- Data: RDS PostgreSQL + ElastiCache Valkey (one cluster shared by queue
  + core, namespaces `queue:*`, `stock:*`, `nik:*`, `ticket:*`,
  `denylist:*`, `cap:*`).
- Async: SQS + DLQ (notifications, etc.).
- Email: SES (production access; built-in Midtrans emails are being
  considered for disabling so only SES emails are sent).
- Storage: S3 for e-ticket PDFs (access via presigned URL).
- Secrets: Secrets Manager (Midtrans Server Key, DB/Valkey credentials,
  JWT keys). No secrets in this repo.
- Observability: CloudWatch + X-Ray (OTel deferred — Q40).
- Domains: `rusuh-tiket.web.id` + `api.rusuh-tiket.web.id` (SSL via ACM —
  not yet present, part of the `dns` module).

## Provisioning checklist (Q25)

| Item | Status |
| --- | --- |
| VPC + subnets + routing | Module `network` — implemented |
| RDS PostgreSQL | Module `data` — implemented |
| ElastiCache Valkey | Module `data` — implemented |
| SQS + DLQ | Module `messaging` — implemented |
| SES (identity + DKIM) | Module `email` — implemented (production access remains a manual step) |
| S3 (e-ticket) | Module `storage` — implemented |
| Secrets Manager | Module `secrets` — implemented (shells only, no values) |
| ECS + ALB | Module `compute` — implemented |
| Domain + ACM/SSL | Module `dns` — implemented (certificate; manual DNS validation) |
| CloudWatch (alarms + dashboard) | Module `observability` — implemented |

Target: all infra ready for the 13 November 2026 evaluation. That
evaluation is a one-shot opportunity — there is no "later" phase for
core infra.

## Layout

```
bootstrap/            # One-time, local state: S3 state bucket + DynamoDB lock table
environments/
  demo/               # 13 Nov evaluation environment (root module: network + further modules)
modules/
  network/            # VPC, subnets, IGW, route tables, optional NAT
  data/               # RDS + ElastiCache Valkey
  compute/            # ECS + ALB
  messaging/          # SQS + DLQ
  email/              # SES
  storage/            # S3
  secrets/            # Secrets Manager
  dns/                # ACM + DNS records
  observability/      # CloudWatch (+ X-Ray)
```

## Branch flow (repo rules)

- `main` = reviewed state. The only commit made directly to `main`
  is this repo's initiation (scaffold).
- All feature work goes through a **feature branch + review (PR)
  first**, never a feature commit directly to `main`.

## Backend state & bootstrap

Terraform state is stored remotely (S3 + DynamoDB lock) — not local
state on individual machines. First-time order:

1. `cd bootstrap && terraform init && terraform apply`
   (local state; note the `state_bucket_name` and `lock_table_name`
   outputs).
2. `cd environments/demo && terraform init \
     -backend-config="bucket=<state_bucket_name>" \
     -backend-config="key=rusuh/demo/terraform.tfstate" \
     -backend-config="region=ap-southeast-3" \
     -backend-config="dynamodb_table=<lock_table_name>"`
3. `terraform plan` → review → `terraform apply`.

The backend in `environments/demo/backend.tf` is intentionally a
partial configuration (no hardcoded bucket name) so no bucket name
is guessed in the repo.

## Conventions

- Region: `ap-southeast-3` (Jakarta) for all resources, except ACM
  if CloudFront is ever used (then `us-east-1` is mandatory).
- Naming: `rusuh-<env>-<name>`. Mandatory tags: `Project=rusuh`,
  `Environment=<env>`, `ManagedBy=terraform`.
- Secrets never enter the repo, tfvars, or committed state.
  `*.tfvars` files are ignored; only `*.example.tfvars` may be
  committed.
- `.terraform.lock.hcl` is intentionally COMMITTED (reproducibility).
- Cost is a presentation constraint; proper is the goal (team
  principle): cheap choices that reduce resilience (e.g. NAT off,
  single-AZ) must have their reasons written in the relevant module
  README, and be flagged as post-evaluation hardening items where
  relevant.
