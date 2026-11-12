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

# The ADOT sidecar's default awsemf exporter writes the queue's OTLP metrics as
# EMF to /metrics/<service.name>; CloudWatch turns them into metrics. Managed
# here so it has a retention and the task role can write to it.
resource "aws_cloudwatch_log_group" "queue_metrics" {
  name              = var.queue_metrics_log_group_name
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-queue-metrics"
  }
}

resource "aws_cloudwatch_log_group" "auth" {
  name              = "/ecs/${var.project}-${var.environment}-auth"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-auth-logs"
  }
}

resource "aws_cloudwatch_log_group" "payment" {
  name              = "/ecs/${var.project}-${var.environment}-payment"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-payment-logs"
  }
}

resource "aws_cloudwatch_log_group" "notification" {
  name              = "/ecs/${var.project}-${var.environment}-notification"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-notification-logs"
  }
}

resource "aws_cloudwatch_log_group" "officer" {
  name              = "/ecs/${var.project}-${var.environment}-officer"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-officer-logs"
  }
}

resource "aws_cloudwatch_log_group" "admin" {
  name              = "/ecs/${var.project}-${var.environment}-admin"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-admin-logs"
  }
}

resource "aws_cloudwatch_log_group" "dukcapil_mock" {
  name              = "/ecs/${var.project}-${var.environment}-dukcapil-mock"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.project}-${var.environment}-dukcapil-mock-logs"
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

# One security group per service (least privilege). Rules are separate
# aws_security_group_rule resources (not inline blocks): the core and
# payment groups reference each other (queue/payment -> core, core ->
# payment), and inline blocks would create a dependency cycle.
resource "aws_security_group" "auth" {
  name        = "${var.project}-${var.environment}-auth-sg"
  description = "ECS tasks for service-auth"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-auth-sg"
  }
}

resource "aws_security_group" "core" {
  name        = "${var.project}-${var.environment}-core-sg"
  description = "ECS tasks for service-core"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-core-sg"
  }
}

resource "aws_security_group" "payment" {
  name        = "${var.project}-${var.environment}-payment-sg"
  description = "ECS tasks for service-payment"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-payment-sg"
  }
}

resource "aws_security_group" "notification" {
  name        = "${var.project}-${var.environment}-notification-sg"
  description = "ECS tasks for service-notification (consumer-only, no ALB)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-notification-sg"
  }
}

resource "aws_security_group" "officer" {
  name        = "${var.project}-${var.environment}-officer-sg"
  description = "ECS tasks for service-officer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-officer-sg"
  }
}

resource "aws_security_group" "admin" {
  name        = "${var.project}-${var.environment}-admin-sg"
  description = "ECS tasks for service-admin"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-admin-sg"
  }
}

resource "aws_security_group" "queue" {
  name        = "${var.project}-${var.environment}-queue-sg"
  description = "ECS tasks for service-queue"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-queue-sg"
  }
}

resource "aws_security_group" "dukcapil_mock" {
  name        = "${var.project}-${var.environment}-dukcapil-mock-sg"
  description = "ECS tasks for the Dukcapil NIK-verification mock (internal only)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-dukcapil-mock-sg"
  }
}

locals {
  # ALB-backed services and the port the ALB reaches them on.
  alb_services = {
    auth    = { security_group_id = aws_security_group.auth.id, port = var.auth_port }
    core    = { security_group_id = aws_security_group.core.id, port = var.core_port }
    payment = { security_group_id = aws_security_group.payment.id, port = var.payment_port }
    officer = { security_group_id = aws_security_group.officer.id, port = var.officer_port }
    admin   = { security_group_id = aws_security_group.admin.id, port = var.admin_port }
    queue   = { security_group_id = aws_security_group.queue.id, port = var.queue_port }
  }

  # All service security groups (used for egress and for the DB/Valkey ingress rules below).
  service_security_group_ids = {
    auth         = aws_security_group.auth.id
    core         = aws_security_group.core.id
    payment      = aws_security_group.payment.id
    notification = aws_security_group.notification.id
    officer      = aws_security_group.officer.id
    admin        = aws_security_group.admin.id
    queue        = aws_security_group.queue.id
  }
}

resource "aws_security_group_rule" "alb_ingress" {
  for_each = local.alb_services

  type              = "ingress"
  security_group_id = each.value.security_group_id

  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "ALB to ${each.key} on its container port"
}

resource "aws_security_group_rule" "egress" {
  for_each = local.service_security_group_ids

  type              = "egress"
  security_group_id = each.value

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Outbound for image pull, SES, SQS, and service calls"
}

# The Dukcapil mock deliberately stays out of service_security_group_ids
# (it needs no Postgres/Valkey ingress), so it gets its own egress rule —
# without it the task cannot even pull its image from ECR.
resource "aws_security_group_rule" "dukcapil_mock_egress" {
  type              = "egress"
  security_group_id = aws_security_group.dukcapil_mock.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Outbound for image pull (ECR, CloudWatch Logs)"
}

# Private service-to-service calls (via Service Connect, never the
# public ALB). queue to core: registerAdmission (POST /v1/core/admission).
resource "aws_security_group_rule" "queue_to_core" {
  type              = "ingress"
  security_group_id = aws_security_group.core.id

  from_port                = var.core_port
  to_port                  = var.core_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.queue.id
  description              = "queue to core: registerAdmission"
}

# payment to core: payment-result notification (POST /v1/internal/payments/notify).
resource "aws_security_group_rule" "payment_to_core" {
  type              = "ingress"
  security_group_id = aws_security_group.core.id

  from_port                = var.core_port
  to_port                  = var.core_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.payment.id
  description              = "payment to core: payment-result notification"
}

# core to payment: start a payment (Snap creation, POST /v1/payment/snap).
resource "aws_security_group_rule" "core_to_payment" {
  type              = "ingress"
  security_group_id = aws_security_group.payment.id

  from_port                = var.payment_port
  to_port                  = var.payment_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.core.id
  description              = "core to payment: start a payment"
}

# Ingress to the data layer, owned here (not in the data module). The data
# module creates the DB/Valkey security groups but no ingress rules, so it
# never needs the ECS security groups as an input — the dependency is
# one-way (compute -> data) and no cycle can form. Access is the same as
# before: every ECS service group may reach Postgres (5432) and Valkey
# (6379); tightening that per service is a separate change.
resource "aws_security_group_rule" "db_ingress" {
  for_each = local.service_security_group_ids

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.db_security_group_id
  source_security_group_id = each.value
  description              = "ECS ${each.key} to Postgres"
}

resource "aws_security_group_rule" "valkey_ingress" {
  for_each = local.service_security_group_ids

  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = var.valkey_security_group_id
  source_security_group_id = each.value
  description              = "ECS ${each.key} to Valkey"
}

resource "aws_service_discovery_http_namespace" "this" {
  name        = var.service_connect_namespace
  description = "Private namespace for ECS Service Connect (service-to-service calls, e.g. core.${var.service_connect_namespace})."

  tags = {
    Name = "${var.project}-${var.environment}-service-connect"
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
    path                = var.core_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

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
    path                = var.queue_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project}-${var.environment}-queue-tg"
  }
}

resource "aws_lb_target_group" "auth" {
  name        = "${var.project}-${var.environment}-auth"
  port        = var.auth_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.auth_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project}-${var.environment}-auth-tg"
  }
}

resource "aws_lb_target_group" "payment" {
  name        = "${var.project}-${var.environment}-payment"
  port        = var.payment_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.payment_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project}-${var.environment}-payment-tg"
  }
}

resource "aws_lb_target_group" "officer" {
  name        = "${var.project}-${var.environment}-officer"
  port        = var.officer_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.officer_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project}-${var.environment}-officer-tg"
  }
}

resource "aws_lb_target_group" "admin" {
  name        = "${var.project}-${var.environment}-admin"
  port        = var.admin_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.admin_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project}-${var.environment}-admin-tg"
  }
}

# Paths that must never be reachable from the internet: the internal
# API (/v1/internal/*) and the synchronous admission endpoint
# (POST /v1/core/admission, queue -> core via Service Connect only).
# This rule has the lowest priority number so it is evaluated before
# the per-service rules below.
locals {
  internal_block_path_patterns = ["/v1/internal/*", "/v1/core/admission", "/v1/core/admission/*"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # When a certificate is set, HTTP redirects to HTTPS (access tokens
  # must never travel over plain HTTP). Until then, HTTP forwards to
  # core (the demo runs on HTTP only).
  dynamic "default_action" {
    for_each = var.certificate_arn != "" ? [1] : []

    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn != "" ? [] : [1]

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.core.arn
    }
  }
}

resource "aws_lb_listener_rule" "internal_block_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }

  condition {
    path_pattern {
      values = local.internal_block_path_patterns
    }
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

resource "aws_lb_listener_rule" "auth_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }

  condition {
    path_pattern {
      values = var.auth_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "core_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }

  condition {
    path_pattern {
      values = var.core_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "payment_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 130

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment.arn
  }

  condition {
    path_pattern {
      values = var.payment_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "officer_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 140

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.officer.arn
  }

  condition {
    path_pattern {
      values = var.officer_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "admin_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }

  condition {
    path_pattern {
      values = var.admin_path_patterns
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

resource "aws_lb_listener_rule" "internal_block_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }

  condition {
    path_pattern {
      values = local.internal_block_path_patterns
    }
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

resource "aws_lb_listener_rule" "auth_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }

  condition {
    path_pattern {
      values = var.auth_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "core_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }

  condition {
    path_pattern {
      values = var.core_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "payment_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 130

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment.arn
  }

  condition {
    path_pattern {
      values = var.payment_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "officer_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 140

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.officer.arn
  }

  condition {
    path_pattern {
      values = var.officer_path_patterns
    }
  }
}

resource "aws_lb_listener_rule" "admin_https" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }

  condition {
    path_pattern {
      values = var.admin_path_patterns
    }
  }
}

# One ECR repository per service. CD copies the release image from
# GHCR into the matching repository, then updates the ECS service
# (see the deploy role below and ci-cd/README.md).
resource "aws_ecr_repository" "auth" {
  name                 = "${var.project}-auth"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-auth"
  }
}

resource "aws_ecr_repository" "core" {
  name                 = "${var.project}-core"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-core"
  }
}

resource "aws_ecr_repository" "payment" {
  name                 = "${var.project}-payment"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-payment"
  }
}

resource "aws_ecr_repository" "notification" {
  name                 = "${var.project}-notification"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-notification"
  }
}

resource "aws_ecr_repository" "officer" {
  name                 = "${var.project}-officer"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-officer"
  }
}

resource "aws_ecr_repository" "admin" {
  name                 = "${var.project}-admin"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-admin"
  }
}

resource "aws_ecr_repository" "queue" {
  name                 = "${var.project}-queue"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-queue"
  }
}

resource "aws_ecr_repository" "dukcapil_mock" {
  name                 = "${var.project}-dukcapil-mock"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-dukcapil-mock"
  }
}

resource "aws_ecr_lifecycle_policy" "auth" {
  repository = aws_ecr_repository.auth.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "core" {
  repository = aws_ecr_repository.core.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "payment" {
  repository = aws_ecr_repository.payment.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "notification" {
  repository = aws_ecr_repository.notification.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "officer" {
  repository = aws_ecr_repository.officer.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "admin" {
  repository = aws_ecr_repository.admin.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "queue" {
  repository = aws_ecr_repository.queue.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

# GitHub OIDC provider (account-wide) + deploy role for the backend CD
# workflow. Trust is restricted to the rusuh-core and rusuh-queue repos
# calling the rusuh-infra backend-cd reusable workflow on a v1 tag, in
# the production environment — no other repo, branch, or workflow can
# assume this role.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "deploy" {
  name = "${var.project}-${var.environment}-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # The org uses GitHub's immutable subjects (owner@id/repo@id), so
            # a rename can't reuse the trust; the name-only forms stay in case
            # the org setting is turned off again.
            "token.actions.githubusercontent.com:sub" = [
              "repo:PT-Meeting-Sampai-Malam-Konsultasi@343369600/rusuh-core@1430487010:environment:production",
              "repo:PT-Meeting-Sampai-Malam-Konsultasi@343369600/rusuh-queue@1430486758:environment:production",
              "repo:PT-Meeting-Sampai-Malam-Konsultasi/rusuh-core:environment:production",
              "repo:PT-Meeting-Sampai-Malam-Konsultasi/rusuh-queue:environment:production",
            ]
            "token.actions.githubusercontent.com:job_workflow_ref" = "PT-Meeting-Sampai-Malam-Konsultasi/rusuh-infra/.github/workflows/backend-cd.yml@refs/tags/v1"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.environment}-deploy"
  }
}

resource "aws_iam_role_policy" "deploy" {
  name = "${var.project}-${var.environment}-deploy"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = [
          aws_ecr_repository.auth.arn,
          aws_ecr_repository.core.arn,
          aws_ecr_repository.payment.arn,
          aws_ecr_repository.notification.arn,
          aws_ecr_repository.officer.arn,
          aws_ecr_repository.admin.arn,
          aws_ecr_repository.queue.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTaskSets",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
        ]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = concat([aws_iam_role.execution.arn], [for r in aws_iam_role.task : r.arn])
      },
    ]
  })
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

# Container `secrets` are resolved with the EXECUTION role (not the
# task role). Without this policy, any service that gets a secret
# fails to start with ResourceInitializationError. Service Connect
# discovery permissions are also on the execution role (the ECS agent
# uses it to resolve service names in the namespace).
resource "aws_iam_role_policy" "execution" {
  name = "${var.project}-${var.environment}-ecs-execution"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "servicediscovery:DiscoverInstances",
            "servicediscovery:GetNamespace",
            "servicediscovery:GetService",
            "servicediscovery:ListInstances",
            "servicediscovery:ListNamespaces",
            "servicediscovery:ListServices",
          ]
          Resource = ["*"]
        },
      ],
      length(local.all_secret_arns) > 0 ? [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = local.all_secret_arns
      }] : [],
      var.secrets_kms_key_arn != "" ? [{
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [var.secrets_kms_key_arn]
      }] : [],
    )
  })
}

# Per-service task roles (Tier 2: least privilege). Each service gets its
# own role, so a compromise or misconfiguration in one service cannot use
# another service's AWS permissions. The split, by design:
# - Every service: its OWN log group only, X-Ray, ECS Exec (SSM messages).
# - SQS: notification + queue CONSUME (receive/delete); auth/core/payment/
#   officer/admin only SEND (they enqueue work for notification/queue).
# - SES: notification only (the sole email sender).
# - S3: core + payment only (e-ticket files).
# If a service later needs a permission it does not have, add it to its
# branch below (one line) instead of widening the shared role.
locals {
  task_services = ["auth", "core", "payment", "notification", "officer", "admin", "queue", "dukcapil-mock"]

  # Services that consume from SQS (receive + delete). The rest only send.
  sqs_consumer_services = toset(["notification", "queue"])
  # Services that read/write e-ticket files in S3.
  s3_services = toset(["core", "payment"])

  task_log_group_arns = {
    auth          = aws_cloudwatch_log_group.auth.arn
    core          = aws_cloudwatch_log_group.core.arn
    payment       = aws_cloudwatch_log_group.payment.arn
    notification  = aws_cloudwatch_log_group.notification.arn
    officer       = aws_cloudwatch_log_group.officer.arn
    admin         = aws_cloudwatch_log_group.admin.arn
    queue         = aws_cloudwatch_log_group.queue.arn
    dukcapil-mock = aws_cloudwatch_log_group.dukcapil_mock.arn
  }
}

resource "aws_iam_role" "task" {
  for_each = toset(local.task_services)

  name = "${var.project}-${var.environment}-ecs-task-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-${var.environment}-ecs-task-${each.key}"
  }
}

resource "aws_iam_role_policy" "task" {
  for_each = toset(local.task_services)

  name = "${var.project}-${var.environment}-ecs-task-${each.key}"
  role = aws_iam_role.task[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = ["${local.task_log_group_arns[each.key]}:*"]
        },
        {
          Effect   = "Allow"
          Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
          Resource = ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
          ]
          Resource = ["*"]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
          ]
          Resource = ["*"]
        },
      ],
      length(var.sqs_queue_arns) > 0 ? [{
        Effect   = "Allow"
        Action   = contains(local.sqs_consumer_services, each.key) ? ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"] : ["sqs:SendMessage", "sqs:GetQueueAttributes"]
        Resource = var.sqs_queue_arns
      }] : [],
      var.s3_bucket_arn != "" && contains(local.s3_services, each.key) ? [{
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = ["${var.s3_bucket_arn}/*"]
      }] : [],
      var.ses_identity_arn != "" && each.key == "notification" ? [{
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = [var.ses_identity_arn]
      }] : [],
      each.key == "queue" ? [{
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.queue_metrics.arn}:*"]
      }] : [],
    )
  })
}

locals {
  all_secret_arns = concat(
    [var.database_url_secret_arn],
    values(var.auth_secrets),
    values(var.core_secrets),
    values(var.payment_secrets),
    values(var.notification_secrets),
    values(var.officer_secrets),
    values(var.admin_secrets),
    values(var.queue_secrets),
  )

  # The Node services read DATABASE_URL and VALKEY_URL; the Go queue reads
  # VALKEY_ADDR and VALKEY_PASSWORD. DATABASE_URL is injected directly from
  # Secrets Manager so its password never appears in Terraform state or the
  # ECS task-definition environment section.

  # VALKEY_URL scheme follows the cluster: a token forces rediss://
  # (AWS requires transit encryption with an auth token); TLS without a
  # token is rediss://; otherwise redis://. ioredis (Node) enables TLS
  # automatically on rediss://, no code change needed.
  valkey_url = (
    var.valkey_auth_token != null
    ? "rediss://:${urlencode(var.valkey_auth_token)}@${var.valkey_host}:${var.valkey_port}"
    : var.valkey_transit_encryption_enabled
    ? "rediss://${var.valkey_host}:${var.valkey_port}"
    : "redis://${var.valkey_host}:${var.valkey_port}"
  )

  node_environment = {
    VALKEY_URL = local.valkey_url
  }

  node_connection_secrets = {
    DATABASE_URL = var.database_url_secret_arn
  }

  # Go queue reads VALKEY_ADDR (host:port) + VALKEY_PASSWORD. It does
  # not use Postgres, so it deliberately gets no DATABASE_URL.
  queue_valkey_environment = merge(
    { VALKEY_ADDR = "${var.valkey_host}:${var.valkey_port}" },
    var.valkey_auth_token != null ? { VALKEY_PASSWORD = var.valkey_auth_token } : {},
  )

  # Per-app SQS/S3/SES wiring under the env var names each app actually
  # reads (verified in apps/*/src/infrastructure/config/environment.js).
  # The former generic names (SQS_NOTIFICATION_URL, S3_BUCKET, SES_DOMAIN)
  # matched no consumer and left the core SQS event bus and the auth mailer
  # unwired. Queue topology: otp (auth -> notification), notification
  # (core -> notification), empty_slot (core -> queue service).
  auth_environment = merge(
    local.node_environment,
    { for k, v in { SQS_QUEUE_URL = try(var.sqs_queue_urls["otp"], "") } : k => v if v != "" },
    var.auth_extra_environment,
  )

  core_environment = merge(
    local.node_environment,
    {
      for k, v in {
        SQS_NOTIFICATION_QUEUE_URL = try(var.sqs_queue_urls["notification"], "")
        SQS_EMPTY_SLOT_QUEUE_URL   = try(var.sqs_queue_urls["empty_slot"], "")
      } : k => v if v != ""
    },
    var.core_extra_environment,
  )

  payment_environment = merge(
    local.node_environment,
    var.payment_extra_environment,
  )

  notification_environment = merge(
    local.node_environment,
    {
      for k, v in {
        SQS_OTP_QUEUE_URL   = try(var.sqs_queue_urls["otp"], "")
        SQS_EMAIL_QUEUE_URL = try(var.sqs_queue_urls["notification"], "")
      } : k => v if v != ""
    },
    var.s3_bucket_name != "" ? { S3_TICKET_BUCKET = var.s3_bucket_name } : {},
    var.ses_domain != "" ? { SES_FROM_EMAIL = "noreply@${var.ses_domain}" } : {},
    var.notification_extra_environment,
  )

  officer_environment = merge(
    local.node_environment,
    var.officer_extra_environment,
  )

  admin_environment = merge(
    local.node_environment,
    var.admin_extra_environment,
  )

  queue_environment = merge(
    local.queue_valkey_environment,
    # ADOT sidecar (same task, localhost): queue exports OTLP to it.
    { OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317" },
    var.queue_extra_environment,
  )
}

resource "aws_ecs_task_definition" "auth" {
  family                   = "${var.project}-${var.environment}-auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.auth_cpu)
  memory                   = tostring(var.auth_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["auth"].arn

  container_definitions = jsonencode([
    {
      name        = "auth"
      image       = var.auth_image
      essential   = true
      stopTimeout = 30
      portMappings = [
        { containerPort = var.auth_port, protocol = "tcp", name = "auth" }
      ]
      environment = [for k, v in local.auth_environment : { name = k, value = v }]
      secrets     = [for k, v in merge(var.auth_secrets, local.node_connection_secrets) : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.auth.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-auth-task"
  }
}

resource "aws_ecs_task_definition" "core" {
  family                   = "${var.project}-${var.environment}-core"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.core_cpu)
  memory                   = tostring(var.core_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["core"].arn

  container_definitions = jsonencode([
    {
      name        = "core"
      image       = var.core_image
      essential   = true
      stopTimeout = 30
      portMappings = [
        { containerPort = var.core_port, protocol = "tcp", name = "core" }
      ]
      environment = [for k, v in local.core_environment : { name = k, value = v }]
      secrets     = [for k, v in merge(var.core_secrets, local.node_connection_secrets) : { name = k, valueFrom = v }]
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

resource "aws_ecs_task_definition" "payment" {
  family                   = "${var.project}-${var.environment}-payment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.payment_cpu)
  memory                   = tostring(var.payment_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["payment"].arn

  container_definitions = jsonencode([
    {
      name        = "payment"
      image       = var.payment_image
      essential   = true
      stopTimeout = 30
      portMappings = [
        { containerPort = var.payment_port, protocol = "tcp", name = "payment" }
      ]
      environment = [for k, v in local.payment_environment : { name = k, value = v }]
      secrets     = [for k, v in merge(var.payment_secrets, local.node_connection_secrets) : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.payment.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-payment-task"
  }
}

resource "aws_ecs_task_definition" "notification" {
  family                   = "${var.project}-${var.environment}-notification"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.notification_cpu)
  memory                   = tostring(var.notification_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["notification"].arn

  container_definitions = jsonencode([
    {
      name        = "notification"
      image       = var.notification_image
      essential   = true
      stopTimeout = 30
      portMappings = [
        { containerPort = var.notification_port, protocol = "tcp", name = "notification" }
      ]
      environment = [for k, v in local.notification_environment : { name = k, value = v }]
      secrets     = [for k, v in merge(var.notification_secrets, local.node_connection_secrets) : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.notification.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-notification-task"
  }
}

resource "aws_ecs_task_definition" "officer" {
  family                   = "${var.project}-${var.environment}-officer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.officer_cpu)
  memory                   = tostring(var.officer_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["officer"].arn

  container_definitions = jsonencode([
    {
      name        = "officer"
      image       = var.officer_image
      essential   = true
      stopTimeout = 30
      portMappings = [
        { containerPort = var.officer_port, protocol = "tcp", name = "officer" }
      ]
      environment = [for k, v in local.officer_environment : { name = k, value = v }]
      secrets     = [for k, v in merge(var.officer_secrets, local.node_connection_secrets) : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.officer.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-officer-task"
  }
}

resource "aws_ecs_task_definition" "admin" {
  family                   = "${var.project}-${var.environment}-admin"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.admin_cpu)
  memory                   = tostring(var.admin_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["admin"].arn

  container_definitions = jsonencode([
    {
      name        = "admin"
      image       = var.admin_image
      essential   = true
      stopTimeout = 30
      portMappings = [
        { containerPort = var.admin_port, protocol = "tcp", name = "admin" }
      ]
      environment = [for k, v in local.admin_environment : { name = k, value = v }]
      secrets     = [for k, v in merge(var.admin_secrets, local.node_connection_secrets) : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.admin.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-admin-task"
  }
}

resource "aws_ecs_task_definition" "queue" {
  family                   = "${var.project}-${var.environment}-queue"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.queue_cpu)
  memory                   = tostring(var.queue_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["queue"].arn

  container_definitions = jsonencode([
    {
      name        = "queue"
      image       = var.queue_image
      essential   = true
      stopTimeout = 45
      portMappings = [
        { containerPort = var.queue_port, protocol = "tcp", name = "queue" },
        # Operator API (ADMIN_PORT): admin calls it over Service Connect
        # (dns_name "queue-admin"), never through the public ALB.
        { containerPort = 8081, protocol = "tcp", name = "queue-admin" }
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
    },
    {
      # ADOT sidecar: receives OTLP from the queue container on
      # localhost:4317/4318 and exports to X-Ray + CloudWatch using
      # the image's default ECS config. Not essential: if the
      # collector stops, the queue keeps serving (spans are dropped).
      name = "adot"
      # Pinned (not :latest): a floating tag can silently change what is
      # deployed. Bump deliberately after verifying the new version.
      image       = "public.ecr.aws/aws-observability/aws-otel-collector:v0.51.0"
      essential   = false
      stopTimeout = 30
      portMappings = [
        { containerPort = 4317, protocol = "tcp", name = "otlp-grpc" },
        { containerPort = 4318, protocol = "tcp", name = "otlp-http" },
      ]
      environment = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.queue.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "adot"
        }
      }
    },
  ])

  tags = {
    Name = "${var.project}-${var.environment}-queue-task"
  }
}

# Mock of the Dukcapil NIK-verification third party (rusuh-mock/
# service-dukcapil). Stateless Express app: no database, no Valkey, no
# AWS SDK calls — only logs, hence the plain task role it inherits from
# task_services. Reached by core over Service Connect as dukcapil:8080.
resource "aws_ecs_task_definition" "dukcapil_mock" {
  family                   = "${var.project}-${var.environment}-dukcapil-mock"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.dukcapil_mock_cpu)
  memory                   = tostring(var.dukcapil_mock_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["dukcapil-mock"].arn

  container_definitions = jsonencode([
    {
      name        = "dukcapil-mock"
      image       = var.dukcapil_mock_image
      essential   = true
      stopTimeout = 30
      portMappings = [
        { containerPort = var.dukcapil_mock_port, protocol = "tcp", name = "dukcapil-mock" }
      ]
      environment = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.dukcapil_mock.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-${var.environment}-dukcapil-mock-task"
  }
}

resource "aws_ecs_service" "auth" {
  name            = "${var.project}-${var.environment}-auth"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = var.auth_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.auth.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "auth"
      discovery_name = "auth"

      client_alias {
        port     = var.auth_port
        dns_name = "auth"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth.arn
    container_name   = "auth"
    container_port   = var.auth_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60
  enable_execute_command            = true

  # CD registers a new task-definition revision on each tag; without
  # this, every terraform apply rolls the service back to the image
  # in tfvars. desired_count is also ignored: the autoscaler owns it.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name = "${var.project}-${var.environment}-auth-service"
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
    security_groups  = [aws_security_group.core.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "core"
      discovery_name = "core"

      client_alias {
        port     = var.core_port
        dns_name = "core"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.core.arn
    container_name   = "core"
    container_port   = var.core_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60
  enable_execute_command            = true

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name = "${var.project}-${var.environment}-core-service"
  }
}

resource "aws_ecs_service" "payment" {
  name            = "${var.project}-${var.environment}-payment"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = var.payment_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.payment.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "payment"
      discovery_name = "payment"

      client_alias {
        port     = var.payment_port
        dns_name = "payment"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.payment.arn
    container_name   = "payment"
    container_port   = var.payment_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60
  enable_execute_command            = true

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name = "${var.project}-${var.environment}-payment-service"
  }
}

resource "aws_ecs_service" "notification" {
  name            = "${var.project}-${var.environment}-notification"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.notification.arn
  desired_count   = var.notification_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.notification.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "notification"
      discovery_name = "notification"

      client_alias {
        port     = var.notification_port
        dns_name = "notification"
      }
    }
  }

  # Consumer-only: no load balancer block and no health check grace
  # period (there is no target group to wait for).

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = "${var.project}-${var.environment}-notification-service"
  }
}

resource "aws_ecs_service" "officer" {
  name            = "${var.project}-${var.environment}-officer"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.officer.arn
  desired_count   = var.officer_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.officer.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "officer"
      discovery_name = "officer"

      client_alias {
        port     = var.officer_port
        dns_name = "officer"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.officer.arn
    container_name   = "officer"
    container_port   = var.officer_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60
  enable_execute_command            = true

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name = "${var.project}-${var.environment}-officer-service"
  }
}

resource "aws_ecs_service" "admin" {
  name            = "${var.project}-${var.environment}-admin"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.admin.arn
  desired_count   = var.admin_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.admin.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "admin"
      discovery_name = "admin"

      client_alias {
        port     = var.admin_port
        dns_name = "admin"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.admin.arn
    container_name   = "admin"
    container_port   = var.admin_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60
  enable_execute_command            = true

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name = "${var.project}-${var.environment}-admin-service"
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
    security_groups  = [aws_security_group.queue.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "queue"
      discovery_name = "queue"

      client_alias {
        port     = var.queue_port
        dns_name = "queue"
      }
    }

    # Operator API alias: admin reaches queue's ADMIN_PORT without the
    # admin mux ever being exposed on the public ALB.
    service {
      port_name      = "queue-admin"
      discovery_name = "queue-admin"

      client_alias {
        port     = 8081
        dns_name = "queue-admin"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.queue.arn
    container_name   = "queue"
    container_port   = var.queue_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60
  enable_execute_command            = true

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name = "${var.project}-${var.environment}-queue-service"
  }
}

resource "aws_ecs_service" "dukcapil_mock" {
  name            = "${var.project}-${var.environment}-dukcapil-mock"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.dukcapil_mock.arn
  desired_count   = var.dukcapil_mock_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.dukcapil_mock.id]
    assign_public_ip = var.assign_public_ip
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.this.arn

    service {
      port_name      = "dukcapil-mock"
      discovery_name = "dukcapil-mock"

      client_alias {
        port     = var.dukcapil_mock_port
        dns_name = "dukcapil"
      }
    }
  }

  # Mock of a third party: internal only — no load balancer block.

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = {
    Name = "${var.project}-${var.environment}-dukcapil-mock-service"
  }
}

# Autoscaling (target tracking on CPU) for the ALB-backed services.
# The notification service is consumer-only and has no autoscaling
# target here; scale it by queue depth instead (follow-up).
resource "aws_appautoscaling_target" "auth" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.auth.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "auth" {
  name               = "${var.project}-${var.environment}-auth-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.auth.resource_id
  scalable_dimension = aws_appautoscaling_target.auth.scalable_dimension
  service_namespace  = aws_appautoscaling_target.auth.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "core" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.core.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "core" {
  name               = "${var.project}-${var.environment}-core-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.core.resource_id
  scalable_dimension = aws_appautoscaling_target.core.scalable_dimension
  service_namespace  = aws_appautoscaling_target.core.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "payment" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.payment.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "payment" {
  name               = "${var.project}-${var.environment}-payment-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.payment.resource_id
  scalable_dimension = aws_appautoscaling_target.payment.scalable_dimension
  service_namespace  = aws_appautoscaling_target.payment.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "officer" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.officer.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "officer" {
  name               = "${var.project}-${var.environment}-officer-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.officer.resource_id
  scalable_dimension = aws_appautoscaling_target.officer.scalable_dimension
  service_namespace  = aws_appautoscaling_target.officer.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "admin" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.admin.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "admin" {
  name               = "${var.project}-${var.environment}-admin-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.admin.resource_id
  scalable_dimension = aws_appautoscaling_target.admin.scalable_dimension
  service_namespace  = aws_appautoscaling_target.admin.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "queue" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.queue.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "queue" {
  name               = "${var.project}-${var.environment}-queue-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.queue.resource_id
  scalable_dimension = aws_appautoscaling_target.queue.scalable_dimension
  service_namespace  = aws_appautoscaling_target.queue.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
