# Module: network

VPC + subnets + routing for one environment.

Demo design:

- VPC `10.0.0.0/16`, 2 AZs (`ap-southeast-3a`, `ap-southeast-3b`).
- Public subnets: ALB only. ECS tasks run in **private** subnets with no
  public IP (production topology); a task is only reachable through
  the ALB.
- Private subnets: ECS tasks + data (RDS, Valkey). Tasks reach the
  internet through the per-AZ NAT gateways, and reach AWS services
  privately through the VPC endpoints.
- Internet Gateway + public/private route tables (one private route
  table per AZ, each routing through that AZ's NAT gateway).

NAT Gateway: **on by default** (`enable_nat_gateway = true`), one per
AZ (~$32/month per gateway plus data processing). This is the
production setting — tasks in private subnets need outbound access
(image pull, Midtrans, SES, SQS). Disable only for a short-lived
throwaway environment. The VPC endpoints (ECR, SQS, Secrets Manager,
CloudWatch Logs, SSM, SES, S3) keep AWS API traffic inside the VPC
so it does not depend on (or pay for) NAT data processing.

VPC Flow Logs are enabled (all traffic, to CloudWatch Logs, 90-day
retention) for network audit.

Status: production hardening on feature branch
`feature/production-hardening`.
