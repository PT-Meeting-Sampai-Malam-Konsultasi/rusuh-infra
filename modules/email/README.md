# Module: email

SES for all outbound email (e-tickets, expiry, notifications).

Resources:

- `aws_sesv2_email_identity` for the sending domain + 2048-bit DKIM.

Manual steps (not possible via Terraform, written explicitly):

- Create the 3 CNAME records from the `dkim_tokens` output in
  Cloudflare — until those records exist, the SES identity stays
  unverified and no email is sent.
- SES production access is an AWS quota request (not a Terraform
  resource) — currently not in place; SES sandbox restricts
  recipients to verified addresses only. Arrange before the
  evaluation.
- Built-in Midtrans emails are being considered for disabling so
  only SES emails are sent (Point 6).
