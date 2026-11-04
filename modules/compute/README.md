# Module: compute

ECS cluster (Fargate) + ALB for service-core (Node.js) and
service-queue (Go).

Resources:

- `aws_ecs_cluster` (Container Insights on for the evaluation).
- `aws_lb` (public, ALB-direct without CloudFront — team direction of
  3 Nov), `core` + `queue` target groups, HTTP listener (always) +
  HTTPS listener (only when `certificate_arn` is set, from the `dns`
  module after the certificate is validated).
- Routing: default → core; path `/api/queue/*` → queue (Q41 module
  scheme; pattern changeable via `queue_path_patterns`).
- Security groups: ALB (public 80/443) → ECS (only from ALB, on each
  service's port).
- Fargate task definitions + services, CloudWatch log groups
  (`/ecs/rusuh-demo-core`, `/ecs/rusuh-demo-queue`). Log groups
  intentionally live in this module (tied to the task definitions),
  not in the observability module — observability holds only alarms
  + dashboard.
- IAM: execution role (managed policy) + task role (logs, X-Ray, and
  dynamic SQS/S3/SES/Secrets statements created only when their
  inputs are set).

Assumptions that MUST be confirmed with service owners before apply
(written here so they do not silently become decisions):

- `core_image`, `queue_image`, `core_port`, `queue_port`: no defaults,
  must come from each service's CI/contract.
- `health_check_path` default `/`: assumption; replace with the real
  health endpoint if different (if wrong, targets become unhealthy).
- Standard env var names (`DB_HOST`, `DB_PORT`, `DB_NAME`,
  `VALKEY_HOST`, `VALKEY_PORT`, `SQS_NOTIFICATION_URL`, `S3_BUCKET`,
  `SES_DOMAIN`): assumptions; service owners can add/override via
  `*_extra_environment` without changing the module.
- Tasks run in public subnets with public IPs (`assign_public_ip
  = true`) because NAT is off (see the network module). Production
  hardening: private subnets + NAT + `assign_public_ip = false`.
