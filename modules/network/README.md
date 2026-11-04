# Modul: network

VPC + subnets + routing untuk satu environment.

Desain (demo):

- VPC `10.0.0.0/16`, 2 AZ (`ap-southeast-3a`, `ap-southeast-3b`).
- Public subnets: ALB + ECS demo (dengan security group ketat).
- Private subnets: data (RDS, Valkey) — tanpa rute internet.
- Internet Gateway + route tables public/private.

Keputusan biaya (ditulis eksplisit, bukan diam-diam): NAT Gateway
**nonaktif secara default** (`enable_nat_gateway = false`) karena
biayanya ~$30+/bulan per gateway dan demo tidak membutuhkannya selama
ECS berjalan di public subnet. Konsekuensi: task ECS di private subnet
tidak bisa outbound (pull image, SES, dsb.) sampai NAT diaktifkan.
Aktifkan NAT + pindahkan ECS ke private subnet sebagai item hardening
untuk production (atau bila demo membutuhkan ECS private).

Status: diimplementasi di feature branch `feature/terraform-foundation`.
