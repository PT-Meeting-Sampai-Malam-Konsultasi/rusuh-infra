# Environment: demo

Environment evaluasi 13 November 2026. Root module ini menghubungkan
modul-modul di `../../modules/` menjadi satu stack yang bisa di-apply.

Status saat scaffold: belum ada modul yang terhubung di `main`.
Modul pertama (`network`) dikerjakan di feature branch
`feature/terraform-foundation`, lalu menyusul `data`, `compute`,
`messaging`, `email`, `storage`, `secrets`, `dns`, `observability`
(dalam urutan dependensi).

## Pakai

1. Bootstrap dulu (lihat `../../bootstrap/README.md`), catat nama bucket
   state dan tabel lock.
2. `terraform init` dengan `-backend-config` (lihat README root).
3. `terraform plan` → periksa dengan teliti → `terraform apply`.

Perhatian: `terraform destroy` di environment ini menghapus seluruh stack
demo. Jangan dijalankan tanpa persetujuan tim.
