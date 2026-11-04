resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }

  tags = {
    Name = "${var.project}-${var.environment}-cluster"
  }
}

resource "aws_cloudwatch_log_group" "core" {
  name              = "/ecs/${var.project}-${var.environment}-core"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-core-logs"
  }
}

resource "aws_cloudwatch_log_group" "queue" {
  name              = "/ecs/${var.project}-${var.environment}-queue"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-queue-logs"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB: public HTTP/HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.environment}-ecs-sg"
  description = "ECS tasks: only from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.core_port
    to_port         = var.core_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = var.queue_port
    to_port         = var.queue_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecs-sg"
  }
}

resource "aws_lb" "this" {
  name                       = "${var.project}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.alb_subnet_ids
  enable_deletion_protection = false

  tags = {
    Name = "${var.project}-${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "core" {
  name        = "${var.project}-${var.environment}-core"
  port        = var.core_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.project}-${var.environment}-core-tg"
  }
}

resource "aws_lb_target_group" "queue" {
  name        = "${var.project}-${var.environment}-queue"
  port        = var.queue_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.project}-${var.environment}-queue-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }
}

resource "aws_lb_listener_rule" "queue_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.queue.arn
  }

  condition {
    path_pattern {
      values = var.queue_path_patterns
    }
  }
}

# HTTPS listener only exists once a certificate ARN is supplied
# (from the dns module, after ACM validation). Until then the demo
# serves HTTP only — see README.md.
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }
}

resource "aws_lb_listener_rule" "queue_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.queue.arn
  }

  condition {
    path_pattern {
      values = var.queue_path_patterns
    }
  }
}

resource "aws_iam_role" "execution" {
  name = "${var.project}-${var.environment}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-${var.environment}-ecs-execution"
  }
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "${var.project}-${var.environment}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-${var.environment}-ecs-task"
  }
}

resource "aws_iam_role_policy" "task" {
  name = "${var.project}-${var.environment}-ecs-task"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = [
            "${aws_cloudwatch_log_group.core.arn}:*",
            "${aws_cloudwatch_log_group.queue.arn}:*",
          ]
        },
        {
          Effect   = "Allow"
          Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
          Resource = ["*"]
        },
      ],
      length(var.sqs_queue_arns) > 0 ? [{
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = var.sqs_queue_arns
      }] : [],
      var.s3_bucket_arn != "" ? [{
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = ["${var.s3_bucket_arn}/*"]
      }] : [],
      var.ses_identity_arn != "" ? [{
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = [var.ses_identity_arn]
      }] : [],
      length(concat(values(var.core_secrets), values(var.queue_secrets))) > 0 ? [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = concat(values(var.core_secrets), values(var.queue_secrets))
      }] : [],
    )
  })
}

locals {
  core_environment = merge(
    {
      DB_HOST     = var.db_address
      DB_PORT     = tostring(var.db_port)
      DB_NAME     = var.db_name
      VALKEY_HOST = var.valkey_host
      VALKEY_PORT = tostring(var.valkey_port)
    },
    var.sqs_notification_queue_url != "" ? { SQS_NOTIFICATION_URL = var.sqs_notification_queue_url } : {},
    var.s3_bucket_name != "" ? { S3_BUCKET = var.s3_bucket_name } : {},
    var.ses_domain != "" ? { SES_DOMAIN = var.ses_domain } : {},
    var.core_extra_environment,
  )

  queue_environment = merge(
    {
      DB_HOST     = var.db_address
      DB_PORT     = tostring(var.db_port)
      DB_NAME     = var.db_name
      VALKEY_HOST = var.valkey_host
      VALKEY_PORT = tostring(var.valkey_port)
    },
    var.sqs_notification_queue_url != "" ? { SQS_NOTIFICATION_URL = var.sqs_notification_queue_url } : {},
    var.s3_bucket_name != "" ? { S3_BUCKET = var.s3_bucket_name } : {},
    var.ses_domain != "" ? { SES_DOMAIN = var.ses_domain } : {},
    var.queue_extra_environment,
  )
}

resource "aws_ecs_task_definition" "core" {
  family                   = "${var.project}-${var.environment}-core"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.core_cpu)
  memory                   = tostring(var.core_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "core"
      image     = var.core_image
      essential = true
      portMappings = [
        { containerPort = var.core_port, protocol = "tcp" }
      ]
      environment = [for k, v in local.core_environment : { name = k, value = v }]
      secrets     = [for k, v in var.core_secrets : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.core.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-core-task"
  }
}

resource "aws_ecs_task_definition" "queue" {
  family                   = "${var.project}-${var.environment}-queue"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.queue_cpu)
  memory                   = tostring(var.queue_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "queue"
      image     = var.queue_image
      essential = true
      portMappings = [
        { containerPort = var.queue_port, protocol = "tcp" }
      ]
      environment = [for k, v in local.queue_environment : { name = k, value = v }]
      secrets     = [for k, v in var.queue_secrets : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.queue.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-queue-task"
  }
}

resource "aws_ecs_service" "core" {
  name            = "${var.project}-${var.environment}-core"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.core.arn
  desired_count   = var.core_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.core.arn
    container_name   = "core"
    container_port   = var.core_port
  }

  tags = {
    Name = "${var.project}-${var.environment}-core-service"
  }
}

resource "aws_ecs_service" "queue" {
  name            = "${var.project}-${var.environment}-queue"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.queue.arn
  desired_count   = var.queue_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.queue.arn
    container_name   = "queue"
    container_port   = var.queue_port
  }

  tags = {
    Name = "${var.project}-${var.environment}-queue-service"
  }
}
