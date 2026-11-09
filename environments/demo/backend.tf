terraform {
  # Partial backend configuration: bucket, key, region, and dynamodb_table
  # are supplied via -backend-config at init time (see ../../README.md).
  # Intentionally empty so no bucket name is hardcoded in the repo.
  backend "s3" {
  }
}
