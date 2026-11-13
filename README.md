# rusuh-infra

Infrastructure-as-code for rusuh (ticket booking): all environments
are defined with Terraform in this repo, separate from the application
repos (`rusuh-core`, `rusuh-queue`, `rusuh-mock`) and the documentation
repo (`rusuh-documentation`).

Platform: AWS Jakarta region (`ap-southeast-3`) — per ADR-0012 in the
documentation repo. Terraform `>= 1.5`, AWS provider `~> 5.0`.

## Architecture (summary)

- Web: Cloudflare Pages (FE team, Wrangler).
- API: Cloudflare (proxy, TLS, WAF and rate limiting) → ALB → ECS
  (seven services: auth, core, payment, notification, officer, admin
  from rusuh-core, plus queue from rusuh-queue). The `api` record is
  a proxied Cloudflare CNAME to the ALB. There is no CloudFront or
  AWS WAF in this stack: the edge was removed because Cloudflare is
  the public entry point. The 1 s cache for `/v1/queue/{evt}/frontier`
  (ADR-0015) is therefore a Cloudflare cache rule, not an AWS setting.
- Data: RDS PostgreSQL + ElastiCache Valkey (primary + replica with
  automatic failover; one cluster shared by queue + core, namespaces
  `q:{evt}:*`, `core:*`, `stream:booking`, `rl:*`).
- Async: SQS + DLQ (notifications, etc.).
- Email: SES (production access; built-in Midtrans emails are being
  considered for disabling so only SES emails are sent).
- Storage: S3 for e-ticket PDFs (access via presigned URL).
- Secrets: Secrets Manager (Midtrans Server Key, DB/Valkey credentials,
  JWT keys). No secrets in this repo.
- Observability: CloudWatch + X-Ray (OTel deferred — Q40; the queue
  service exports OTLP to an ADOT sidecar, core logs to CloudWatch).
- Domains: `rusuh-tiket.web.id` + `api.rusuh-tiket.web.id`, DNS and TLS
  at Cloudflare. The ALB listens on HTTP :80 only; it is reachable from
  Cloudflare, not meant to be called directly. HTTPS to the origin would
  need an ACM certificate and `certificate_arn` (the compute module still
  supports it).

## Production hardening

This is a production-ready setup, not an evaluation-only one:

- **Network:** ALB public, ECS tasks in private subnets with no public
  IP, one NAT gateway per AZ, VPC endpoints for AWS services
  (ECR, SQS, Secrets Manager, CloudWatch Logs, SSM, SES, S3), VPC
  Flow Logs on.
- **Data:** RDS Multi-AZ + deletion protection + 7-day automated
  backups + final snapshot on delete; Valkey Multi-AZ with failover
  (in-transit encryption is OFF by default — enable only after the
  clients are verified TLS-compatible, see below); S3 versioning +
  encryption + public access block.
- **IAM:** one task role per service (least privilege — SQS send vs
  receive, SES notification-only, S3 core+payment-only); secrets via
  Secrets Manager, resolved by the execution role. ECR repositories
  are immutable (`IMMUTABLE`); the ADOT sidecar image is pinned
  (`aws-otel-collector:v0.51.0`, not `:latest`).
- **Audit:** VPC Flow Logs on; CloudTrail is OPT-IN (off by default —
  the account baseline trail `soldev-lz-trail`, multi-region, already
  covers audit; enable `enable_cloudtrail` only if this environment
  needs its own trail). CloudWatch alarms (ALB 5xx, DLQ depth) notify
  via SNS — `alarm_email` is required, and the recipient must confirm
  the SNS subscription after apply.
- **Backup/restore:** see `docs/runbook-backup-restore.md`.

RDS manages and stores the master password in Secrets Manager; Terraform
exposes only the managed-secret ARN. A separate application `DATABASE_URL`
secret remains necessary until the applications can consume the RDS-managed
JSON secret directly. Known follow-ups (not in this repo yet): RDS password
rotation needs an application/runtime integration; Valkey in-transit encryption (the wiring is ready: Terraform builds a `rediss://`
`VALKEY_URL` and a `VALKEY_PASSWORD` for the queue as soon as
`valkey_transit_encryption_enabled = true` and `valkey_auth_token` are
set, and rusuh-core needs no code change — ioredis enables TLS on
`rediss://` automatically — but rusuh-queue/Go must enable TLS in its
client first, a team follow-up); HTTPS from Cloudflare to the ALB would
need an ACM certificate and `certificate_arn` set at apply time (the ACM
certificate is no longer created by Terraform).
Connection URLs: the Node services get `DATABASE_URL` from a required
Secrets Manager ARN plus `VALKEY_URL`; the Go queue gets `VALKEY_ADDR`
(host:port) + `VALKEY_PASSWORD` and deliberately no `DATABASE_URL`.
The database URI never appears in Terraform-generated task-definition
environment variables. The data-layer security groups carry no ingress
rules in the data module — the compute module creates the ingress
rules (DB 5432, Valkey 6379) from the ECS security groups, so the
dependency is one-way (compute → data) and no cycle can form.

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
| ECS + ALB | Module `compute` — implemented (7 services) |
| Edge (TLS, WAF, rate limit, cache) | Cloudflare (outside Terraform). The former `edge` module (CloudFront + AWS WAF) was removed |
| Domain + TLS | Cloudflare DNS and TLS (outside Terraform). The former `dns` module (ACM certificate) was removed |
| CloudWatch (alarms + dashboard) | Module `observability` — implemented |

Target: all infra ready for the 13 November 2026 evaluation. That
evaluation is a one-shot opportunity — there is no "later" phase for
core infra.

## Layout

```
bootstrap/            # One-time, local state: S3 state bucket + DynamoDB lock table
environments/
  prod/               # production environment (root module wiring all modules)
modules/
  network/            # VPC, subnets, IGW, route tables, optional NAT
  data/               # RDS + ElastiCache Valkey
  compute/            # ECS + ALB
  messaging/          # SQS + DLQ
  email/              # SES
  storage/            # S3
  secrets/            # Secrets Manager
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
2. `cd environments/prod && terraform init \
     -backend-config="bucket=<state_bucket_name>" \
     -backend-config="key=msmk/prod/terraform.tfstate" \
     -backend-config="region=ap-southeast-3" \
     -backend-config="dynamodb_table=<lock_table_name>"`
3. `terraform plan` → review → `terraform apply`.

The backend in `environments/prod/backend.tf` is intentionally a
partial configuration (no hardcoded bucket name) so no bucket name
is guessed in the repo.

## Conventions

- Region: `ap-southeast-3` (Jakarta) for all resources.
- Naming: `msmk-<env>-<name>`. Mandatory tags: `Project=msmk`,
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

## CI/CD (shared pipeline)

Reusable GitHub Actions workflows for the backend repos live in `.github/workflows/`:
- `backend-ci.yml`: checks, secret scan, Dockerfile lint, SAST, image build and scan, and the GHCR push on `main`;
- `backend-cd.yml`: on a release tag, copies the image to ECR and deploys it to ECS.

Each backend repo calls them with its own commands and pins `@v1`. Each stage has an on/off switch: an org variable
that a repo can override.

Everything else for CI/CD is under [`ci-cd/`](ci-cd/):
- [`ci-cd/README.md`](ci-cd/README.md): how to plug a repo in, the switches, CD variables and the release checklist;
- `ci-cd/examples/`: starter callers;
- `ci-cd/tests/fixtures/`: the fixtures the self-test (`.github/workflows/cicd-self-test.yml`) runs on;
- `ci-cd/docs/`: the design and the plan;
- `make -C ci-cd lint`: actionlint over the workflows and examples.

The workflows themselves stay in `.github/workflows/` because GitHub only runs reusable workflows from there.
- Tracked in issue #2 (CICD-01).

This repo is public so the public backend repos can call its workflows. Like the Terraform, it never holds secrets,
state or account values.

## ECS Exec (operator access)

All ECS services have `enable_execute_command = true` and the task
role has the SSM session permissions, so an operator can get a shell
inside a running task during the evaluation (there is no bastion):

```sh
aws ecs execute-command \
  --cluster msmk-prod-cluster \
  --task <task-id> \
  --container core \
  --interactive \
  --command "/bin/sh"
```

List tasks first with `aws ecs list-tasks --cluster
msmk-prod-cluster --service-name msmk-prod-core-service`. The
session is logged to CloudWatch (`/ecs/msmk-prod-<service>`). The
queue service's admin port stays private — it is not exposed through
the ALB; reach it via Service Connect or ECS Exec.
