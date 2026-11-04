# Module: observability

CloudWatch alarms + dashboard for the evaluation (one screen to
watch the demo).

Resources:

- ALB 5xx alarm (default threshold 10 per 5 minutes).
- DLQ depth alarm per queue (threshold > 0 — the DLQ must stay
  empty under normal conditions).
- Overview dashboard: ALB requests + 5xx, ECS CPU/memory per service,
  DLQ depth (the DLQ widget only appears when DLQs are provided).

Notes:

- Alarms here have no actions yet (no SNS/email): their status is
  visible in the CloudWatch console. Wire them to SNS/email when the
  team is ready — an alarm must not go off unheard during the
  evaluation.
- ECS log groups intentionally live in the compute module (tied to
  the task definitions), not here.
- Tracing: X-Ray (Q40) is SDK-side; the `xray:PutTraceSegments`
  permission is already in the compute task role. OTel deferred.
- Logging rules stand: structured JSON + `booking_id`/`request_id`
  correlation + masked NIK + no tokens/OTPs/secrets (30 Oct); the DB
  audit trail is separate from CloudWatch operational logs.
