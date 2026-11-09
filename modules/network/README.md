# Module: network

VPC + subnets + routing for one environment.

Demo design:

- VPC `10.0.0.0/16`, 2 AZs (`ap-southeast-3a`, `ap-southeast-3b`).
- Public subnets: ALB + demo ECS (with tight security groups).
- Private subnets: data (RDS, Valkey) — no internet route.
- Internet Gateway + public/private route tables.

Cost decision (written explicitly, not silently): the NAT Gateway is
**off by default** (`enable_nat_gateway = false`) because it costs
~$30+/month per gateway and the demo does not need it while ECS runs
in public subnets. Consequence: ECS tasks in private subnets cannot
reach outbound (image pull, SES, etc.) until NAT is enabled. Enable
NAT + move ECS to private subnets as a production hardening item
(or if the demo needs private ECS).

Status: implemented on feature branch `feature/terraform-foundation`.
