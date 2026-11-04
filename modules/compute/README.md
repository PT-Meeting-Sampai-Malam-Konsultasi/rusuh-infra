# Modul: compute

ECS cluster (Fargate) + ALB untuk service-core (Node.js) dan
service-queue (Go).

Resource:

- `aws_ecs_cluster` (Container Insights on untuk evaluasi).
- `aws_lb` (public, ALB-direct tanpa CloudFront — arah tim 3 Nov),
  target groups `core` + `queue`, listener HTTP (selalu) + HTTPS
  (hanya bila `certificate_arn` diisi, dari modul `dns` setelah
  sertifikat tervalidasi).
- Routing: default → core; path `/api/queue/*` → queue (skema modul
  Q41; pola bisa diubah via `queue_path_patterns`).
- Security groups: ALB (80/443 publik) → ECS (hanya dari ALB, pada
  port masing-masing service).
- Task definitions + services Fargate, log groups CloudWatch
  (`/ecs/rusuh-demo-core`, `/ecs/rusuh-demo-queue`). Log group sengaja
  tinggal di modul ini (terikat task definition), bukan di modul
  observability — modul observability hanya berisi alarm + dashboard.
- IAM: execution role (managed policy) + task role (logs, X-Ray, dan
  statement dinamis SQS/S3/SES/Secrets yang hanya dibuat bila inputnya
  diisi).

Asumsi yang HARUS dikonfirmasi ke pemilik service sebelum apply
(ditulis di sini supaya tidak diam-diam jadi keputusan):

- `core_image`, `queue_image`, `core_port`, `queue_port`: tanpa default,
  wajib diisi dari CI/kontrak service masing-masing.
- `health_check_path` default `/`: asumsi; ganti dengan endpoint health
  asli bila berbeda (bila salah, target jadi unhealthy).
- Nama env var standar (`DB_HOST`, `DB_PORT`, `DB_NAME`, `VALKEY_HOST`,
  `VALKEY_PORT`, `SQS_NOTIFICATION_URL`, `S3_BUCKET`, `SES_DOMAIN`):
  asumsi; pemilik service bisa menambah/menimpa lewat
  `*_extra_environment` tanpa mengubah modul.
- Task berjalan di public subnet dengan public IP (`assign_public_ip
  = true`) karena NAT nonaktif (lihat modul network). Hardening
  production: private subnet + NAT + `assign_public_ip = false`.
