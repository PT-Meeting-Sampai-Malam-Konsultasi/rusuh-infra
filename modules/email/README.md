# Modul: email

SES untuk semua email keluar (e-tiket, expired, notifikasi).

Resource:

- `aws_sesv2_email_identity` untuk domain pengirim + DKIM 2048-bit.

Langkah manual (tidak bisa via Terraform, ditulis eksplisit):

- Buat 3 CNAME record dari output `dkim_tokens` di Cloudflare —
  sampai record ini ada, identitas SES berstatus unverified dan email
  tidak terkirim.
- Production access SES adalah permintaan kuota AWS (bukan resource
  Terraform) — saat ini belum ada; SES sandbox membatasi penerima ke
  alamat terverifikasi saja. Urus sebelum evaluasi.
- Email bawaan Midtrans dipertimbangkan nonaktif supaya hanya email
  SES yang terkirim (Point 6).
