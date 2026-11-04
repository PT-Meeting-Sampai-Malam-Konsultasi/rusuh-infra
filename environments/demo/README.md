# Environment: demo

Environment evaluasi 13 November 2026. Root module ini menghubungkan
modul-modul di `../../modules/` menjadi satu stack yang bisa di-apply.

Status di branch ini: modul `network` sudah terhubung (lihat `main.tf`).
Menyusul setelah branch ini di-review dan di-merge: `data`, `compute`,
`messaging`, `email`, `storage`, `secrets`, `dns`, `observability`
(dalam urutan dependensi).

## Pakai

1. Bootstrap dulu (lihat `../../bootstrap/README.md`), catat nama bucket
   state dan tabel lock.
2. `terraform init` dengan `-backend-config` (lihat README root).
3. `terraform plan` → periksa dengan teliti → `terraform apply`.

Perhatian: `terraform destroy` di environment ini menghapus seluruh stack
demo. Jangan dijalankan tanpa persetujuan tim.
