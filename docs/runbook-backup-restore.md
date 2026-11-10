# Runbook: Backup & Restore (Tier 3)

How the production data is protected, and how to restore it. This is the
operator procedure — read it before you need it, not during an incident.

## What is backed up

| Data | Mechanism | Retention / setting |
|---|---|---|
| Postgres (RDS) | Automated backups (RDS) + Multi-AZ standby | `db_backup_retention_period` = 7 days (default); `skip_final_snapshot = false`, so deleting the instance takes a final snapshot first; `deletion_protection = true` |
| Valkey (ElastiCache) | Multi-AZ with automatic failover (primary + replica) | In-memory state is rebuilt from Postgres on failover; the queue state (`q:{evt}:*`) is ephemeral by design and is re-derived from bookings |
| E-tickets (S3) | S3 versioning + server-side encryption | Versioning `Enabled`; restore = copy a previous version over the current key |
| Terraform state | S3 backend + DynamoDB lock | State bucket versioning (bootstrap); never edit state by hand |
| Audit trail | CloudTrail → dedicated S3 bucket | Versioning `Enabled` on the trail bucket; log file validation on |

## Restore procedures

### Postgres: point-in-time recovery (PITR)

1. In the AWS console, go to RDS → Databases → the `msmk-demo-db` instance
   → Actions → **Restore to point in time**.
2. Pick the target time (within the 7-day retention window) and a new
   instance identifier (for example `msmk-demo-db-restore`).
3. Wait for the new instance to become available, then point the ECS
   services at it: update the `db_address` the compute module receives
   (re-apply Terraform with the restored endpoint), or rename the
   restored instance to the original identifier after deleting the
   broken one (only with `deletion_protection` temporarily off).
4. Verify: the core service `/readyz` returns healthy and a test booking
   reads/writes correctly.

Do **not** restore by replaying SQL dumps — PITR is the supported path.

### Postgres: restore from the final snapshot

If the instance was deleted, a final snapshot exists (because
`skip_final_snapshot = false`). In RDS → Snapshots, select it →
**Restore snapshot** → a new instance. Then follow step 3 above.

### Valkey: failover

Automatic. ElastiCache promotes the replica when the primary fails;
the primary endpoint address does not change, so the services reconnect
without a config change. If the whole cluster is lost, the services
fall back to rebuilding queue state from Postgres (the queue state is
ephemeral; bookings are the source of truth).

### S3 e-ticket: restore a previous version

1. In S3 → the `msmk-demo-etiket-*` bucket → find the object key.
2. Show versions → select the previous version → **Download** (or copy
   it over the current key to make it current again).
3. The presigned URLs are generated on demand, so no service change is
   needed after the restore.

### CloudTrail / Flow Logs: investigation

- CloudTrail events: S3 → the `msmk-demo-cloudtrail-*` bucket →
  `AWSLogs/<account-id>/CloudTrail/`. Use Athena or download the JSON.
- VPC Flow Logs: CloudWatch → Log groups →
  `/aws/vpc/msmk-demo-flow-logs`. Filter by ENI / IP / port.

## Who can do this

Restores change live data. They are done by the operator with AWS
access to the demo account, after confirming with the team. Never
restore onto the live database in place — always restore to a **new**
instance/bucket key first, verify, then cut over.
