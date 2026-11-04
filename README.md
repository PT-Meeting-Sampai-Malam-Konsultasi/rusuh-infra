# rusuh-infra

Infrastructure-as-code untuk rusuh (tiket booking): semua environment
didefinisikan dengan Terraform di repo ini, terpisah dari repo aplikasi
(`rusuh-core`, `rusuh-queue`, `rusuh-mock`) dan repo dokumentasi
(`rusuh-documentation`).

Platform: AWS region Jakarta (`ap-southeast-3`) — sesuai ADR-0012 di repo
dokumentasi. Terraform `>= 1.5`, AWS provider `~> 5.0`.

## Arsitektur (ringkas)

- Web: Cloudflare Pages (tim FE, Wrangler).
- API: ALB → ECS (service-core Node.js + service-queue Go). CloudFront di
  depan API bersifat opsional (keputusan tim masih terbuka); jalur
  ALB-direct adalah yang berlaku sampai diputuskan lain.
- Data: RDS PostgreSQL + ElastiCache Valkey (cluster bersama queue + core,
  namespace `queue:*`, `stock:*`, `nik:*`, `ticket:*`, `denylist:*`,
  `cap:*`).
- Async: SQS + DLQ (notifikasi dkk).
- Email: SES (production access; email bawaan Midtrans dipertimbangkan
  nonaktif supaya hanya email SES yang terkirim).
- Storage: S3 untuk PDF e-tiket (akses via presigned URL).
- Secret: Secrets Manager (Server Key Midtrans, kredensial DB/Valkey, kunci
  JWT). Tidak ada secret di repo ini.
- Observabilitas: CloudWatch + X-Ray (OTel ditunda — Q40).
- Domain: `rusuh-tiket.web.id` + `api.rusuh-tiket.web.id` (SSL via ACM —
  saat ini belum ada, bagian dari modul `dns`).

## Checklist provisioning (Q25)

| Item | Status |
| --- | --- |
| VPC + subnets + routing | Modul `network` (feature `feature/terraform-foundation`) |
| RDS PostgreSQL | Modul `data` — belum diimplementasi |
| ElastiCache Valkey | Modul `data` — belum diimplementasi |
| SQS + DLQ | Modul `messaging` — belum diimplementasi |
| SES production access | Modul `email` — belum diimplementasi |
| S3 (e-tiket) | Modul `storage` — belum diimplementasi |
| Secrets Manager | Modul `secrets` — belum diimplementasi |
| ECS + ALB | Modul `compute` — belum diimplementasi |
| Domain + ACM/SSL | Modul `dns` — belum diimplementasi |
| CloudWatch (+ X-Ray) | Modul `observability` — belum diimplementasi |

Target: seluruh infra siap untuk evaluasi 13 November 2026. Evaluasi itu
satu kesempatan — tidak ada fase "nanti" untuk infra inti.

## Struktur

```
bootstrap/            # Sekali jalan, local state: bucket state S3 + tabel lock DynamoDB
environments/
  demo/               # Environment evaluasi 13 Nov (root module: network + modul berikutnya)
modules/
  network/            # VPC, subnets, IGW, route tables, NAT opsional
  data/               # RDS + ElastiCache Valkey
  compute/            # ECS + ALB
  messaging/          # SQS + DLQ
  email/              # SES
  storage/            # S3
  secrets/            # Secrets Manager
  dns/                # ACM + DNS records
  observability/      # CloudWatch (+ X-Ray)
```

## Alur branch (aturan repo ini)

- `main` = state yang sudah direview. Satu-satunya commit langsung ke
  `main` adalah inisiasi repo ini (scaffold).
- Semua pekerjaan fitur lewat **feature branch + review (PR) dulu**,
  tidak pernah commit fitur langsung ke `main`.

## Backend state & bootstrap

State Terraform disimpan remote (S3 + lock DynamoDB) — bukan local state
di mesin masing-masing. Urutan pertama kali:

1. `cd bootstrap && terraform init && terraform apply`
   (local state; catat output `state_bucket_name` dan `lock_table_name`).
2. `cd environments/demo && terraform init \
     -backend-config="bucket=<state_bucket_name>" \
     -backend-config="key=rusuh/demo/terraform.tfstate" \
     -backend-config="region=ap-southeast-3" \
     -backend-config="dynamodb_table=<lock_table_name>"`
3. `terraform plan` → periksa → `terraform apply`.

Backend di `environments/demo/backend.tf` sengaja ditulis sebagai partial
configuration (tanpa nama bucket hardcoded) supaya tidak ada nama bucket
yang ditebak-tebak di repo.

## Konvensi

- Region: `ap-southeast-3` (Jakarta) untuk semua resource, kecuali ACM
  bila suatu hari memakai CloudFront (saat itu wajib `us-east-1`).
- Penamaan: `rusuh-<env>-<nama>`. Tag wajib: `Project=rusuh`,
  `Environment=<env>`, `ManagedBy=terraform`.
- Secret tidak pernah masuk repo, tfvars, atau state yang di-commit.
  File `*.tfvars` di-ignore; yang boleh di-commit hanya
  `*.example.tfvars`.
- `.terraform.lock.hcl` sengaja DI-COMMIT (reproducibility).
- Biaya adalah constraint presentasi, proper adalah tujuan (prinsip tim):
  pilihan hemat yang mengurangi ketahanan (mis. NAT off, single-AZ)
  harus ditulis alasannya di README modul yang bersangkutan, dan
  ditandai sebagai item hardening pasca-evaluasi bila relevan.
