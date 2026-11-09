resource "aws_s3_bucket" "etiket" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name = "${var.project}-${var.environment}-etiket"
  }
}

resource "aws_s3_bucket_versioning" "etiket" {
  bucket = aws_s3_bucket.etiket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "etiket" {
  bucket = aws_s3_bucket.etiket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "etiket" {
  bucket = aws_s3_bucket.etiket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "etiket" {
  bucket = aws_s3_bucket.etiket.id

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
