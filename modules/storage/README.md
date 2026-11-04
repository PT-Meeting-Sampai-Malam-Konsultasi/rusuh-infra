# Modul: storage

S3 untuk PDF e-tiket (Q28).

Ketentuan:

- Bucket private penuh (public access block semua on); akses hanya via
  presigned URL (usulan 7 hari — durasi diputuskan aplikasi, bukan
  modul ini).
- Versioning + enkripsi default aktif; lifecycle membatalkan multipart
  upload yang tidak selesai setelah 7 hari.
- `force_destroy = false` (default): `terraform destroy` gagal selama
  masih ada objek — perlindungan data. Ubah ke true hanya bila tim
  sadar konsekuensinya.
- `bucket_name` tanpa default: nama bucket unik secara global; pola
  yang disarankan `rusuh-demo-etiket-<aws-account-id>`.
