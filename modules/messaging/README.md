# Modul: messaging

SQS + DLQ untuk pekerjaan async (notifikasi dkk., Q27).

Ketentuan:

- Satu queue + DLQ per jenis pekerjaan; redrive policy (maxReceiveCount
  + deadLetterTarget) wajib — pesan gagal tidak boleh hilang diam-diam.
- Visibility timeout harus lebih besar dari waktu pemrosesan terlama
  yang diharapkan (bukan default mentah).
- Relay-target job notifikasi (SQS vs direct-read outbox ADR-0013) masih
  terbuka di diskusi tim; modul ini menyiapkan SQS-nya, keputusan relay
  mengikuti hasil diskusi.

Status: belum diimplementasi.
