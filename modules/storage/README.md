# Module: storage

S3 for e-ticket PDFs (Q28).

Rules:

- Fully private bucket (all public access blocks on); access only via
  presigned URLs (7-day proposal — the duration is decided by the
  application, not this module).
- Versioning + default encryption on; lifecycle aborts incomplete
  multipart uploads after 7 days.
- `force_destroy = false` (default): `terraform destroy` fails while
  objects remain — data protection. Set to true only if the team
  understands the consequence.
- `bucket_name` has no default: bucket names are globally unique;
  suggested pattern `msmk-demo-etiket-<aws-account-id>`.
