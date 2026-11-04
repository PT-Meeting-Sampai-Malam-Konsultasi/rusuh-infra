# Modul: secrets

Secrets Manager untuk semua secret runtime — tapi modul ini hanya
membuat SHELL-nya (resource secret tanpa nilai).

Alasan (prinsip keamanan, bukan keterbatasan): nilai secret yang
ditulis di Terraform akan tersimpan di state dalam bentuk yang bisa
dibaca — itu sama saja dengan menaruh secret di repo. Maka:

- Nilai diisi out-of-band oleh pemilik (AWS console / CLI
  `put-secret-value`), tidak pernah via Terraform, tfvars, atau chat.
- Isi yang direncanakan: Server Key Midtrans (backend-only), password
  DB, token Valkey, kunci JWT (Ed25519), dan secret service lain.
- Kebijakan rotasi belum diputuskan tim.

Alur pakai dua tahap untuk task ECS: apply dengan `secrets = {}`
dulu (atau dengan daftar nama saja) → isi nilai out-of-band → apply
lagi dengan ARN secret di `core_secrets`/`queue_secrets` modul compute.
