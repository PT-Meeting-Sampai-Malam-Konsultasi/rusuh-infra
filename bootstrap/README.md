# Bootstrap: remote state backend (one-time, local state)

Creates the S3 bucket for Terraform state + the DynamoDB table for
locking. Run once before any environment is initialized with a remote
backend.

## Usage

```bash
cd bootstrap
terraform init
terraform apply -var="state_bucket_name=<globally-unique-bucket-name>"
```

Note the `state_bucket_name` and `lock_table_name` outputs, then use
them as `-backend-config` when running `terraform init` in
`environments/prod` (see the root README).

## Notes

- This configuration uses **local state** (intentionally): the remote
  backend does not exist before bootstrap runs — this chicken-and-egg
  problem is solved with a single local apply.
- The local bootstrap state only records 2 resources (bucket + table).
  Keep its `terraform.tfstate` file somewhere safe; if lost, both
  resources can be `import`ed back (there is no application data in
  it, only the state infrastructure itself).
- Bucket names must be globally unique across all AWS accounts.
  Suggested pattern: `msmk-tfstate-<aws-account-id>`.
