# Modul: data

RDS PostgreSQL (kebenaran durable: booking, payment, audit) +
ElastiCache Valkey (gerbang live: stok, kuota NIK, tiket, denylist, cap).

Resource:

- `aws_db_subnet_group` + `aws_db_instance` (Postgres, private subnets).
- `aws_elasticache_subnet_group` + `aws_elasticache_replication_group`
  (Valkey, private subnets).
- Security group masing-masing: ingress hanya dari security group ECS
  (input `ecs_security_group_id` dari modul compute). Tidak ada akses
  dari internet.

Keputusan demo (ditulis eksplisit):

- RDS single-AZ, `db.t4g.micro`, 20 GB, backup 7 hari,
  `deletion_protection = false`, `skip_final_snapshot = true` — supaya
  iterasi demo tidak terkunci. Untuk production: Multi-AZ + deletion
  protection on + final snapshot.
- Valkey single node (`num_cache_clusters = 1`, tanpa failover), tanpa
  transit encryption dan tanpa AUTH token secara default. Alasan: di
  private subnet + SG-restricted, dan Valkey hanya menyimpan HMAC NIK
  (bukan NIK mentah), counter, dan tiket. Hardening production:
  transit encryption + AUTH token (keduanya harus di-set bersamaan —
  constraint API AWS) + multi-node dengan failover.
- Password DB dan token Valkey adalah variabel sensitif tanpa default:
  di-supply via tfvars (gitignored) atau out-of-band, tidak pernah
  di-commit.

Dependensi: butuh `vpc_id` + `private_subnet_ids` (modul network) dan
`ecs_security_group_id` (modul compute). Tidak ada dependensi siklik:
security group ECS tidak bergantung pada task definition, sehingga
alur network → compute SG → data SG → data → compute task definition
valid di graph Terraform.
