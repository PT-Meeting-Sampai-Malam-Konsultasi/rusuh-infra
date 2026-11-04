# Module: secrets

Secrets Manager for all runtime secrets — but this module only
creates their SHELLs (secret resources without values).

Reason (a security principle, not a limitation): a secret value
written in Terraform ends up stored in state in readable form —
which is equivalent to putting the secret in the repo. Therefore:

- Values are filled out-of-band by the owner (AWS console / CLI
  `put-secret-value`), never via Terraform, tfvars, or chat.
- Planned contents: Midtrans Server Key (backend-only), DB password,
  Valkey token, JWT keys (Ed25519), and other service secrets.
- Rotation policy not yet decided by the team.

Two-step flow for ECS tasks: apply with `secrets = {}` first (or
with the name list only) → fill values out-of-band → apply again
with the secret ARNs in the compute module's `core_secrets`/
`queue_secrets`.
