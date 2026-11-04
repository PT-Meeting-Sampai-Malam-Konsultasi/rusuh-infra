# Modul: storage

S3 untuk PDF e-tiket (Q28).

Ketentuan:

- Bucket private; akses hanya via presigned URL (usulan 7 hari).
- Versioning + lifecycle (objek lama dibersihkan sesuai kebijakan
  retensi yang diputuskan tim).
- Tidak ada akses publik; enkripsi default aktif.

Status: belum diimplementasi.
