# Module: data

RDS PostgreSQL (durable truth: bookings, payments, audit) +
ElastiCache Valkey (live gate: stock, NIK quota, tickets, denylist, cap).

Resources:

- `aws_db_subnet_group` + `aws_db_instance` (Postgres, private subnets).
- `aws_elasticache_subnet_group` + `aws_elasticache_replication_group`
  (Valkey, private subnets) + `aws_elasticache_parameter_group`
  (`maxmemory-policy = noeviction`) + a CloudWatch alarm on the
  primary node's `DatabaseMemoryUsagePercentage` (threshold 85%).
- One security group each: ingress only from the ECS service security
  groups (`ecs_security_group_ids` input from the compute module, one
  per service). No internet access.

Demo decisions (written explicitly):

- RDS single-AZ, `db.t4g.micro`, 20 GB, 7-day backups,
  `deletion_protection = false`, `skip_final_snapshot = true` — so
  demo iteration is not locked in. For production: Multi-AZ +
  deletion protection on + final snapshot.
- Valkey primary + replica (`num_cache_clusters = 2`,
  `automatic_failover_enabled = true`, `multi_az_enabled = true`),
  no transit encryption and no AUTH token by default. The replica
  is required: the queue relay uses `WAIT 1`, which needs a replica
  to acknowledge writes (a single node makes it fail). Cost is 2x a
  single node. Reason for no TLS/AUTH: private subnets +
  SG-restricted, and Valkey only stores HMACs of NIKs (not raw
  NIKs), counters, and tickets. Production hardening: transit
  encryption + AUTH token (both must be set together — AWS API
  constraint) + multi-node with failover.
- Valkey `maxmemory-policy = noeviction` (custom parameter group):
  the default `volatile-lru` would silently evict `q:{evt}:*` keys,
  which all have an expiry by design. With noeviction, a full node
  rejects writes loudly instead of losing queue state.
- Valkey key namespaces in use (see `api/shared-keys.md` in the
  documentation repo): `q:{evt}:*` (queue), `core:*` (core),
  `stream:booking`, `rl:*`.
- The DB password and Valkey token are sensitive variables without
  defaults: supply via tfvars (gitignored) or out-of-band, never
  commit them.

Dependencies: needs `vpc_id` + `private_subnet_ids` (network module)
and `ecs_security_group_ids` (compute module). No cyclic dependency:
the ECS security groups do not depend on the task definitions, so
the chain network → compute SGs → data SGs → data → compute task
definitions is valid in the Terraform graph.
