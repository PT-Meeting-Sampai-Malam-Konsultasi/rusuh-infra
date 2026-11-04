# Modul: compute

ECS cluster + ALB untuk service-core (Node.js) dan service-queue (Go).

Ketentuan:

- API direct ke ALB (tanpa CloudFront) sesuai arah tim 3 Nov; ACM wajib
  untuk subdomain api (lihat modul `dns`).
- Task/service definition per service; image dari registry masing-masing
  service (build/deploy tetap di repo service yang bersangkutan, modul
  ini hanya menyediakan platformnya).
- Keputusan terbuka saat implementasi: Fargate vs EC2 (biaya vs kontrol),
  autoscaling, health check path per service.

Status: belum diimplementasi.
