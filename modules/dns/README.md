# Modul: dns

ACM + DNS records untuk `api.rusuh-tiket.web.id`.

Resource:

- `aws_acm_certificate` (validasi DNS) untuk subdomain api, di region
  yang sama dengan ALB (arah ALB-direct).

Langkah manual (tidak bisa via Terraform tanpa token Cloudflare,
ditulis eksplisit):

- Buat DNS record dari output `domain_validation_options` di
  Cloudflare — sampai record ini ada, sertifikat berstatus
  PENDING_VALIDATION dan tidak bisa dipasang ke listener ALB.
- Setelah tervalidasi, isi `certificate_arn` modul compute (via
  environment demo) lalu apply lagi — listener HTTPS 443 aktif.
- Sampai saat itu demo berjalan di HTTP saja (listener 80).
- Bila tim suatu hari memilih CloudFront di depan API, sertifikat
  harus pindah ke `us-east-1` (requirement CloudFront) — modul ini
  perlu diubah saat itu.
- SSL saat ini belum ada sama sekali — modul ini + langkah validasi
  di atas yang menutup gap itu.
