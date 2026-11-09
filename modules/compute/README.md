# Module: compute

ECS cluster (Fargate) + ALB for the seven rusuh services:

| Service | App | Port | Public routes |
| --- | --- | --- | --- |
| auth | rusuh-core `apps/auth` | 8081 | `/v1/auth/*` |
| core | rusuh-core `apps/core` | 8082 | `/v1/core/*` |
| payment | rusuh-core `apps/payment` | 8083 | `/v1/payment/*` |
| notification | rusuh-core `apps/notification` | 8084 | (none — consumer-only) |
| officer | rusuh-core `apps/officer` | 8085 | `/v1/officer/*` |
| admin | rusuh-core `apps/admin` | 8086 | `/v1/admin/*` |
| queue | rusuh-queue | (variable) | `/v1/queue/*`, `/v1/queue/devices` |

Resources:

- `aws_ecs_cluster` (Container Insights on for the evaluation).
- `aws_lb` (public, behind CloudFront — see the edge module),
  one target group per ALB-backed service, HTTP listener (always) +
  HTTPS listener (only when `certificate_arn` is set, from the `dns`
  module after the certificate is validated).
- Routing (ADR-0017 `/v1/` scheme): default → core; one listener
  rule per service (HTTP + HTTPS, priority 100–150). Internal paths
  are blocked from the public listeners with a fixed-response 404
  (priority 10): `/v1/internal/*` and `/v1/core/admission` — those
  are reachable only via Service Connect (see below).
- HTTP listener (port 80): redirects 301 to HTTPS once
  `certificate_arn` is set; until then it forwards to core.
- Security groups: one per service. ALB → each service's SG on its
  container port. Inter-service traffic is SG-based, not CIDR:
  queue → core (admission), core → payment (start a payment),
  payment → core (payment-result notification). Separate
  `aws_security_group_rule` resources (not inline blocks) avoid the
  core/payment SG cycle.
- ECS Service Connect namespace (`rusuh.local` by default): every
  service is discoverable as `<service>.rusuh.local`. Inter-service
  calls (queue → core admission, core ↔ payment) go through Service
  Connect, never the public ALB. The public ALB must not be used for
  service-to-service traffic.
- Fargate task definitions + services, CloudWatch log groups
  (`/ecs/rusuh-demo-<service>`). Log groups intentionally live in
  this module (tied to the task definitions), not in the
  observability module — observability holds only alarms +
  dashboard.
- ECR repository per service (`rusuh-<service>`, scan on push,
  lifecycle policy keeps the 10 most recent images). The CD pipeline
  copies the release image from GHCR into ECR, then updates the ECS
  service.
- GitHub OIDC provider (`token.actions.githubusercontent.com`) +
  deploy role. Trust is restricted to
  `repo:PT-Meeting-Sampai-Malam-Konsultasi/rusuh-infra:environment:production`
  and `job_workflow_ref` =
  `PT-Meeting-Sampai-Malam-Konsultasi/rusuh-infra/.github/workflows/backend-cd.yml@refs/tags/v1`.
  Permissions: ECR GetAuthorizationToken + push to the seven
  repositories, ECS Describe/Update/Register, and `iam:PassRole` on
  the execution + task roles.
- IAM: execution role (managed policy + inline policy for
  `secretsmanager:GetSecretValue` on the configured secret ARNs,
  `kms:Decrypt` when `secrets_kms_key_arn` is set, and Service
  Connect discovery) + task role (logs, X-Ray, SSM session for ECS
  Exec, and dynamic SQS/S3/SES statements created only when their
  inputs are set). Container secrets are resolved by the execution
  role; the task role has no `GetSecretValue`.

Defaults and operational knobs (all variables, tunable):

- CPU/memory: 512/1024 for every service (raised for the load tests).
- `deployment_circuit_breaker { enable = true, rollback = true }`
  and `health_check_grace_period_seconds = 60` on all services.
- `lifecycle { ignore_changes = [task_definition] }` on all services
  — CD updates the task definition outside Terraform. Autoscaled
  services also ignore `desired_count`, otherwise apply fights the
  autoscaler.
- Autoscaling (target tracking CPU 70%, min 1, max 3) on the six
  ALB-backed services. Notification is consumer-only and has no
  autoscaling yet (scale by queue depth — follow-up).
- `deregistration_delay = 30` on all target groups (default 300 s
  would stall every deploy ~5 min per task).
- `stopTimeout = 45` on the queue container (it ends open SSE
  streams over ~25 s, then finishes in-flight requests), `30` on the
  others.
- Health checks (matcher `200`): queue and core `/readyz`, the other
  five `/health/live`.
- ECS Exec (`enable_execute_command = true` on all services) — see
  the root README for usage.

ADOT sidecar (queue only): the queue task definition has a second
container `adot` (`public.ecr.aws/aws-observability/aws-otel-collector`,
`essential = false`, ports 4317 gRPC / 4318 HTTP, logs to the queue
log group with prefix `adot`). The queue app exports OTLP to
`http://localhost:4317`; the collector forwards to X-Ray +
CloudWatch. Core only logs to CloudWatch (no OTLP).

Assumptions that MUST be confirmed with service owners before apply
(written here so they do not silently become decisions):

- `auth_image`, `core_image`, `payment_image`,
  `notification_image`, `officer_image`, `admin_image`,
  `queue_image`: no defaults, must come from each service's CI.
- `core_port`, `queue_port`: no defaults. `auth_port`,
  `payment_port`, `notification_port`, `officer_port`, `admin_port`
  default to 8081/8083/8084/8085/8086.
- Health check paths: queue and core `/readyz`, others
  `/health/live`. If a service does not answer its path, its targets
  become unhealthy.
- Standard env var names (`DB_HOST`, `DB_PORT`, `DB_NAME`,
  `VALKEY_HOST`, `VALKEY_PORT`, `SQS_NOTIFICATION_URL`, `S3_BUCKET`,
  `SES_DOMAIN`): assumptions; service owners can add/override via
  `*_extra_environment` without changing the module.
- Tasks run in public subnets with public IPs (`assign_public_ip
  = true`) because NAT is off (see the network module). Production
  hardening: private subnets + NAT + `assign_public_ip = false`.
- The Service Connect discovery permissions on the execution role
  and the ADOT sidecar's default config are only verified at the
  first apply (no apply has run in this environment yet).
