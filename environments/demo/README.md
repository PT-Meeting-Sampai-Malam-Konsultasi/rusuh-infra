# Environment: demo

Environment evaluasi 13 November 2026. Root module ini menghubungkan
modul-modul di `../../modules/` menjadi satu stack yang bisa di-apply.

Status di branch ini: seluruh modul sudah terhubung (lihat `main.tf`):
`network`, `data`, `compute`, `messaging`, `email`, `storage`,
`secrets`, `dns`, `observability`.

## Pakai

1. Bootstrap dulu (lihat `../../bootstrap/README.md`), catat nama bucket
   state dan tabel lock.
2. `terraform init` dengan `-backend-config` (lihat README root).
3. `terraform plan` → periksa dengan teliti → `terraform apply`.

## Variabel wajib (tanpa default)

`db_password`, `core_image`, `queue_image`, `core_port`, `queue_port`,
`s3_bucket_name` — isi lewat file tfvars (gitignored, tidak pernah
di-commit) atau `-var`. Contoh: `terraform plan
-var-file="demo.tfvars"` dengan `demo.tfvars` berisi keenam nilai itu.

## Langkah dua tahap (ditulis eksplisit, bukan asumsi)

- Secret: apply dulu (secret berupa shell kosong) → isi nilai via
  console/CLI AWS oleh pemilik → apply lagi dengan ARN secret di
  `core_secrets`/`queue_secrets`.
- DNS/SES: setelah apply, buat record validasi dari output
  `certificate_validation_options` dan token DKIM modul email di
  Cloudflare → sertifikat tervalidasi → isi `certificate_arn` lalu
  apply lagi untuk mengaktifkan listener HTTPS 443. Sampai saat itu
  demo berjalan di HTTP saja.
- Production access SES adalah permintaan kuota manual (bukan
  Terraform) — urus sebelum evaluasi.

## Asumsi yang harus dikonfirmasi sebelum apply

- Image, port, health check path (`/`), dan nama env var standar
  (lihat README modul compute) — konfirmasi ke pemilik service-core
  dan service-queue.
- Wiring compute mengasumsikan queue `notification` ada di
  `var.queues` — bila `queues` di-override, pertahankan `notification`
  atau ubah wiring.
- Topologi demo: task ECS di public subnet + public IP (NAT
  nonaktif). Bila NAT diaktifkan, ubah `ecs_subnet_ids` ke private
  subnet dan `assign_public_ip` ke false.

Perhatian: `terraform destroy` di environment ini menghapus seluruh stack
demo. Jangan dijalankan tanpa persetujuan tim.
