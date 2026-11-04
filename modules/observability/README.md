# Modul: observability

CloudWatch (+ X-Ray) untuk logs, metrik, dan alarm.

Ketentuan:

- Semua module aplikasi nge-log JSON terstruktur + korelasi
  `booking_id`/`request_id` + NIK masked + tanpa token/OTP/secret
  (aturan 30 Okt). Audit trail DB dibedakan dari operational log
  CloudWatch.
- Trace: X-Ray (Q40; OTel ditunda, dipertimbangkan lagi bila perlu
  multi-backend).
- Alarm minimal: error rate, latensi p95, kedalaman DLQ, dan lag relay
  outbox (ambang menyusul dari load test).

Status: belum diimplementasi.
