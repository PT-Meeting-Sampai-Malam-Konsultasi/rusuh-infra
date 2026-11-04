# Modul: secrets

Secrets Manager untuk semua secret runtime.

Ketentuan:

- Isi: Server Key Midtrans (backend-only, tidak pernah ke FE),
  kredensial DB/Valkey, kunci JWT (Ed25519), dan secret service lain.
- Tidak ada secret di repo, tfvars, atau state yang di-commit.
  Aplikasi membaca secret saat runtime (bukan build time).
- Rotasi secret mengikuti kebijakan tim (belum diputuskan).

Status: belum diimplementasi.
