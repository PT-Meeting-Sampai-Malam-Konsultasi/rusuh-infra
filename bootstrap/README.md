# Bootstrap: remote state backend (sekali jalan, local state)

Membuat bucket S3 untuk Terraform state + tabel DynamoDB untuk lock.
Jalankan sekali sebelum environment mana pun di-init dengan backend remote.

## Pakai

```bash
cd bootstrap
terraform init
terraform apply -var="state_bucket_name=<nama-bucket-unik-global>"
```

Catat output `state_bucket_name` dan `lock_table_name`, lalu pakai sebagai
`-backend-config` saat `terraform init` di `environments/demo`
(lihat README root).

## Catatan

- Konfigurasi ini memakai **local state** (sengaja): backend remote belum
  ada sebelum bootstrap jalan — masalah ayam-telur ini diselesaikan
  dengan satu kali apply lokal.
- State lokal bootstrap ini hanya merekam 2 resource (bucket + tabel).
  Simpan file `terraform.tfstate`-nya di tempat aman; bila hilang,
  kedua resource bisa di-`import` kembali (tidak ada data aplikasi di
  dalamnya, hanya infrastruktur state itu sendiri).
- Nama bucket harus unik secara global di semua akun AWS. Pola yang
  disarankan: `rusuh-tfstate-<aws-account-id>`.
