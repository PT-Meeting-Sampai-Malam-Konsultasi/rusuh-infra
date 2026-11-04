# Modul: data

RDS PostgreSQL (kebenaran durable: booking, payment, audit) +
ElastiCache Valkey (gerbang live: stok, kuota NIK, tiket, denylist, cap).

Ketentuan:

- Hanya di private subnets modul `network`; security group hanya
  menerima dari security group ECS.
- Valkey: satu cluster bersama queue + core (namespace `queue:*`,
  `stock:*`, `nik:*`, `ticket:*`, `denylist:*`, `cap:*`); Multi-AZ +
  AOF (posisi fail-closed saat Valkey down total — lihat keputusan tim).
- Parameter yang harus diputuskan saat implementasi (biaya vs
  ketahanan): instance class, Multi-AZ RDS, retention backup,
  maintenance window.

Status: belum diimplementasi.
