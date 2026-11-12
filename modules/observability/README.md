# Module: observability

CloudWatch alarms + dashboard for the evaluation (one screen to
watch the demo).

Resources:

- ALB 5xx alarm (default threshold 10 per 5 minutes).
- DLQ depth alarm per queue (threshold > 0 — the DLQ must stay
  empty under normal conditions).
- Overview dashboard: ALB requests + 5xx, ECS CPU/memory per service,
  DLQ depth (the DLQ widget only appears when DLQs are provided).
- Queue alarms (`queue.tf`, NFR-09-Q2), each notifying the alarm topic
  on ALARM and on recovery:
  - `<prefix>-queue-no-running-task`: Container Insights
    `RunningTaskCount` below 1 for 2 minutes (missing data breaches).
  - `<prefix>-queue-unhealthy-targets`: queue target group
    `UnHealthyHostCount` above 0 for 3 minutes.
  - `<prefix>-queue-5xx`: queue target group 5xx above
    `queue_alarm_5xx_threshold` (default 5) in 5 minutes.
  - Log metric filters on the queue's JSON logs (`{ $.msg = "…" }`,
    namespace `Rusuh/Queue`) with one alarm each: booking event
    dead-lettered, background routine stopped, held leases past their
    end, admission not recorded in core (more than 2 in 5 minutes), tick
    failed (more than 5 a minute for 3 minutes).

Notes:

- Alarms notify the SNS topic `<prefix>-alarms` (email to
  `alarm_email`). The recipient must confirm the subscription, or no
  alarm reaches anyone. The data module's Valkey memory alarm uses the
  same topic (`alarm_topic_arn` output).
- Drill: `aws cloudwatch set-alarm-state --alarm-name <name>
  --state-value ALARM --state-reason drill` sends the notification
  without breaking anything; the next evaluation sets the real state.
- ECS log groups intentionally live in the compute module (tied to
  the task definitions), not here.
- Tracing: X-Ray (Q40) is SDK-side; the `xray:PutTraceSegments`
  permission is already in the compute task role. OTel deferred.
- Logging rules stand: structured JSON + `booking_id`/`request_id`
  correlation + masked NIK + no tokens/OTPs/secrets (30 Oct); the DB
  audit trail is separate from CloudWatch operational logs.
