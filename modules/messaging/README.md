# Modul: messaging

SQS + DLQ untuk pekerjaan async (notifikasi dkk., Q27).

Resource per queue:

- `aws_sqs_queue` utama + `aws_sqs_queue` DLQ (`<nama>-dlq`).
- `redrive_policy` di queue utama (maxReceiveCount, default 5).
- `redrive_allow_policy` di DLQ (`byQueue`, hanya dari queue utama
  yang bersangkutan).

Ketentuan:

- `visibility_timeout_seconds` (default 300 dtk) harus lebih besar dari
  waktu pemrosesan terlama yang diharapkan — bila tidak, pesan yang
  sedang diproses bisa diproses dua kali.
- Pesan gagal tidak boleh hilang diam-diam: setelah maxReceiveCount
  percobaan, pesan pindah ke DLQ; kedalaman DLQ di-alarm oleh modul
  observability (DLQ harus tetap kosong di kondisi normal).
- Default hanya membuat queue `notification`. Tambah queue lain lewat
  variabel `queues` bila ada pekerjaan async baru.
- Keputusan relay-target job notifikasi (SQS vs direct-read outbox
  ADR-0013) masih terbuka di diskusi tim; modul ini menyiapkan
  SQS-nya, keputusan relay mengikuti hasil diskusi.
