# Modul: dns

ACM + DNS records untuk `rusuh-tiket.web.id` dan
`api.rusuh-tiket.web.id`.

Ketentuan:

- Sertifikat ACM untuk subdomain api (wajib untuk ALB-direct; region =
  region ALB. Bila suatu hari memakai CloudFront, sertifikat pindah ke
  `us-east-1`).
- Record DNS di Cloudflare: apex → Pages (CNAME flattening, tim FE via
  Wrangler); api CNAME → DNS ALB, DNS-only (grey cloud) selama tanpa
  CloudFront.
- Keputusan CloudFront vs ALB-direct masih terbuka di tim; modul ini
  menunggu keputusan itu sebelum record final ditulis.
- SSL saat ini belum ada sama sekali — modul ini yang menutup gap itu.

Status: belum diimplementasi.
