resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.environment}-public-${var.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project}-${var.environment}-private-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# One private route table per AZ: each AZ's private subnets route their
# default traffic through that AZ's own NAT gateway (no cross-AZ NAT
# dependency, so one AZ's failure does not cut the others off).
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-private-rt-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# NAT Gateway: one per AZ (production HA). Each AZ's private subnets
# route through the NAT gateway in the same AZ, so an AZ failure only
# affects that AZ's outbound traffic. Cost is ~$32/month per gateway
# plus data processing; the demo default is now ON (production-ready).
# Disable only for a short-lived throwaway environment.
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-nat-eip-${var.availability_zones[count.index]}"
  }
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project}-${var.environment}-nat-${var.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

# ---------------------------------------------------------------------------
# VPC Flow Logs (Tier 3: audit). All VPC traffic is logged to CloudWatch
# so network-level access can be audited and investigated.
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project}-${var.environment}-flow-logs"
  retention_in_days = 90

  tags = {
    Name = "${var.project}-${var.environment}-flow-logs"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.project}-${var.environment}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-${var.environment}-vpc-flow-logs"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project}-${var.environment}-vpc-flow-logs"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn         = aws_iam_role.flow_logs.arn

  tags = {
    Name = "${var.project}-${var.environment}-flow-logs"
  }
}

# ---------------------------------------------------------------------------
# VPC endpoints (Tier 2: enterprise). Private connectivity to the AWS
# services the tasks use, so that traffic never leaves the VPC and does
# not depend on (or pay for) NAT data processing for AWS APIs.
# Interface endpoints cost ~$7/month per AZ each; the S3 gateway
# endpoint has no hourly charge.
# ---------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-${var.environment}-vpce-sg"
  description = "Interface VPC endpoints: HTTPS from inside the VPC only"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-vpce-sg"
  }
}

locals {
  # Interface endpoints the tasks need. ecr.* = image pulls; sqs = the
  # event/notification queues; secretsmanager = container secrets;
  # logs = CloudWatch Logs; ssm/ssmmessages/ec2messages = ECS Exec
  # (SSM sessions from private subnets); email = SES.
  interface_endpoint_services = toset([
    "ecr.api",
    "ecr.dkr",
    "sqs",
    "secretsmanager",
    "logs",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "email",
  ])
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-${var.environment}-vpce-${each.key}"
  }
}

# S3 gateway endpoint (no hourly charge): attaches to the private route
# tables so e-ticket reads/writes stay inside AWS.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = {
    Name = "${var.project}-${var.environment}-vpce-s3"
  }
}
