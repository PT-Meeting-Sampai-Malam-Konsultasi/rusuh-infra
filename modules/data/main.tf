resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "Postgres access from ECS tasks only"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ecs_security_group_ids

    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-db-sg"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-db"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage      = var.db_allocated_storage
  storage_encrypted      = true
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = false
  publicly_accessible     = false

  tags = {
    Name = "${var.project}-${var.environment}-db"
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-valkey"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-valkey-subnet-group"
  }
}

resource "aws_security_group" "valkey" {
  name        = "${var.project}-${var.environment}-valkey-sg"
  description = "Valkey access from ECS tasks only"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ecs_security_group_ids

    content {
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-valkey-sg"
  }
}

# The default parameter group uses maxmemory-policy volatile-lru,
# which silently evicts keys that have an expiry — every q:{evt}:*
# key has one by design. noeviction fails writes loudly instead of
# losing queue state (places, leases, counters).
resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-valkey-noeviction"
  family = "valkey7"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }

  tags = {
    Name = "${var.project}-${var.environment}-valkey-noeviction"
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.project}-${var.environment}-valkey"
  description          = "Valkey for rusuh demo (queue state q:{evt}:*, core state core:*, booking stream, rate limits)"

  engine                     = "valkey"
  engine_version             = var.valkey_engine_version
  node_type                  = var.valkey_node_type
  num_cache_clusters         = var.valkey_num_cache_clusters
  parameter_group_name       = aws_elasticache_parameter_group.this.name
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.valkey.id]
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # NOTE: auth_token requires transit_encryption_enabled = true (AWS API
  # constraint). Defaults (false/null) are consistent; set both together.
  transit_encryption_enabled = var.valkey_transit_encryption_enabled
  auth_token                 = var.valkey_auth_token

  tags = {
    Name = "${var.project}-${var.environment}-valkey"
  }
}

# Alarm on the primary node's memory usage. With noeviction, a full
# node rejects writes instead of evicting, so memory pressure must be
# visible before it becomes an outage. The primary node is
# <replication_group_id>-001; the replica holds the same data, so its
# usage tracks the primary.
resource "aws_cloudwatch_metric_alarm" "valkey_memory" {
  alarm_name          = "${var.project}-${var.environment}-valkey-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Valkey primary node memory usage above 85% (noeviction: writes fail instead of evicting)"
  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.this.id}-001"
  }
  treat_missing_data = "notBreaching"

  tags = {
    Name = "${var.project}-${var.environment}-valkey-memory"
  }
}
