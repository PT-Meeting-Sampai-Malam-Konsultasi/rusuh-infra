# Modul: email

SES untuk semua email keluar (e-tiket, expired, notifikasi).

Ketentuan:

- Production access SES wajib diurus (saat ini belum ada; SES sandbox
  membatasi penerima ke alamat terverifikasi saja).
- Domain identity + DKIM untuk `rusuh-tiket.web.id`.
- Email bawaan Midtrans dipertimbangkan nonaktif supaya hanya email SES
  yang terkirim (Point 6).

Status: belum diimplementasi.
