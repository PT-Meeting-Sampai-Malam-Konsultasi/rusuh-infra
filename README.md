# rusuh-infra

Infrastructure-as-code for rusuh (ticket booking): all environments
are defined with Terraform in this repo, separate from the application
repos (`rusuh-core`, `rusuh-queue`, `rusuh-mock`) and the documentation
repo (`rusuh-documentation`).

Platform: AWS Jakarta region (`ap-southeast-3`) — per ADR-0012 in the
documentation repo. Terraform `>= 1.5`, AWS provider `~> 5.0`.

## Architecture (summary)

- Web: Cloudflare Pages (FE team, Wrangler).
- API: CloudFront → ALB → ECS (seven services: auth, core, payment,
  notification, officer, admin from rusuh-core, plus queue from
  rusuh-queue). CloudFront caches `/v1/queue/{evt}/frontier` for 1 s
  (ADR-0015) and puts a WAF in front of the API; the rest is
  pass-through. The `api` DNS record points at the CloudFront
  domain, not directly at the ALB.
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
- Domains: `rusuh-tiket.web.id` + `api.rusuh-tiket.web.id` (SSL via ACM —
  not yet present, part of the `dns` module; the CloudFront custom
  domain needs a separate certificate in us-east-1, see the edge
  module README).

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
| CloudFront + WAF | Module `edge` — implemented (distribution + Web ACL; custom domain needs a us-east-1 ACM certificate, TBD) |
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
  edge/               # CloudFront + WAF in front of the ALB
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

- Region: `ap-southeast-3` (Jakarta) for all resources, except
  CloudFront-scoped resources (WAFv2 Web ACL, ACM for the CloudFront
  custom domain) — those are `us-east-1` (mandatory).
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
  --cluster msmk-demo-cluster \
  --task <task-id> \
  --container core \
  --interactive \
  --command "/bin/sh"
```

List tasks first with `aws ecs list-tasks --cluster
msmk-demo-cluster --service-name msmk-demo-core-service`. The
session is logged to CloudWatch (`/ecs/msmk-demo-<service>`). The
queue service's admin port stays private — it is not exposed through
the ALB; reach it via Service Connect or ECS Exec.
