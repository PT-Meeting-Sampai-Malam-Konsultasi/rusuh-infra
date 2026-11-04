# Module: data

RDS PostgreSQL (durable truth: bookings, payments, audit) +
ElastiCache Valkey (live gate: stock, NIK quota, tickets, denylist, cap).

Resources:

- `aws_db_subnet_group` + `aws_db_instance` (Postgres, private subnets).
- `aws_elasticache_subnet_group` + `aws_elasticache_replication_group`
  (Valkey, private subnets).
- One security group each: ingress only from the ECS security group
  (`ecs_security_group_id` input from the compute module). No internet
  access.

Demo decisions (written explicitly):

- RDS single-AZ, `db.t4g.micro`, 20 GB, 7-day backups,
  `deletion_protection = false`, `skip_final_snapshot = true` — so
  demo iteration is not locked in. For production: Multi-AZ +
  deletion protection on + final snapshot.
- Valkey single node (`num_cache_clusters = 1`, no failover), no
  transit encryption and no AUTH token by default. Reason: private
  subnets + SG-restricted, and Valkey only stores HMACs of NIKs (not
  raw NIKs), counters, and tickets. Production hardening: transit
  encryption + AUTH token (both must be set together — AWS API
  constraint) + multi-node with failover.
- The DB password and Valkey token are sensitive variables without
  defaults: supply via tfvars (gitignored) or out-of-band, never
  commit them.

Dependencies: needs `vpc_id` + `private_subnet_ids` (network module)
and `ecs_security_group_id` (compute module). No cyclic dependency:
the ECS security group does not depend on the task definition, so
the chain network → compute SG → data SG → data → compute task
definition is valid in the Terraform graph.
