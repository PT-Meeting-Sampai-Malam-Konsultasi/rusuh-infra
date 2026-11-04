# Modul: observability

CloudWatch alarm + dashboard untuk evaluasi (satu layar untuk
memantau demo).

Resource:

- Alarm ALB 5xx (threshold default 10 per 5 menit).
- Alarm kedalaman DLQ per queue (threshold > 0 — DLQ harus tetap
  kosong di kondisi normal).
- Dashboard overview: request + 5xx ALB, CPU/memori ECS per service,
  kedalaman DLQ (widget DLQ hanya muncul bila ada DLQ yang diinput).

Catatan:

- Alarm di sini belum punya aksi (tanpa SNS/email): statusnya terlihat
  di console CloudWatch. Hubungkan ke SNS/email saat tim siap —
  jangan sampai alarm berbunyi tanpa ada yang mendengar saat evaluasi.
- Log group ECS sengaja tinggal di modul compute (terikat task
  definition), bukan di sini.
- Trace: X-Ray (Q40) bersifat SDK-side; permission
  `xray:PutTraceSegments` sudah ada di task role modul compute. OTel
  ditunda.
- Aturan log tetap: JSON terstruktur + korelasi `booking_id`/
  `request_id` + NIK masked + tanpa token/OTP/secret (30 Okt); audit
  trail DB dibedakan dari operational log CloudWatch.
