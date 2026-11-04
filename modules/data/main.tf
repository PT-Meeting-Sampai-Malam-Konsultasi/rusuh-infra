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

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
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

  allocated_storage   = var.db_allocated_storage
  storage_encrypted   = true
  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = true
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

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
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

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.project}-${var.environment}-valkey"
  description          = "Valkey for rusuh demo (stock, NIK quota, tickets, denylist, cap)"

  engine               = "valkey"
  engine_version       = var.valkey_engine_version
  node_type            = var.valkey_node_type
  num_cache_clusters   = var.valkey_num_cache_clusters
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.valkey.id]
  automatic_failover_enabled = false
  multi_az_enabled           = false

  # NOTE: auth_token requires transit_encryption_enabled = true (AWS API
  # constraint). Defaults (false/null) are consistent; set both together.
  transit_encryption_enabled = var.valkey_transit_encryption_enabled
  auth_token                 = var.valkey_auth_token

  tags = {
    Name = "${var.project}-${var.environment}-valkey"
  }
}
