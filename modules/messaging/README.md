# Module: messaging

SQS + DLQ for async jobs (notifications, etc., Q27).

Resources per queue:

- Main `aws_sqs_queue` + DLQ `aws_sqs_queue` (`<name>-dlq`).
- `redrive_policy` on the main queue (maxReceiveCount, default 5).
- `redrive_allow_policy` on the DLQ (`byQueue`, only from the
  corresponding main queue).

Rules:

- `visibility_timeout_seconds` (default 300 s) must exceed the longest
  expected processing time — otherwise a message being processed can
  be processed twice.
- Failed messages must not disappear silently: after maxReceiveCount
  attempts, a message moves to the DLQ; DLQ depth is alarmed by the
  observability module (the DLQ must stay empty under normal
  conditions).
- By default only the `notification` queue is created. Add other
  queues via the `queues` variable when new async jobs appear.
- The notification-job relay-target decision (SQS vs direct-read
  outbox, ADR-0013) is still open in team discussion; this module
  provides the SQS side, and the relay decision follows the
  discussion outcome.
