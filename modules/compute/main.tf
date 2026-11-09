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

  # All service security groups (used for egress and for the data module).
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
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-auth"
  }
}

resource "aws_ecr_repository" "core" {
  name                 = "${var.project}-core"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-core"
  }
}

resource "aws_ecr_repository" "payment" {
  name                 = "${var.project}-payment"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-payment"
  }
}

resource "aws_ecr_repository" "notification" {
  name                 = "${var.project}-notification"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-notification"
  }
}

resource "aws_ecr_repository" "officer" {
  name                 = "${var.project}-officer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-officer"
  }
}

resource "aws_ecr_repository" "admin" {
  name                 = "${var.project}-admin"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-admin"
  }
}

resource "aws_ecr_repository" "queue" {
  name                 = "${var.project}-queue"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-queue"
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
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Well-known thumbprint for token.actions.githubusercontent.com.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "${var.project}-${var.environment}-github-oidc"
  }
}

resource "aws_iam_role" "deploy" {
  name = "${var.project}-${var.environment}-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = [
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
        Resource = [aws_iam_role.execution.arn, aws_iam_role.task.arn]
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
            "${aws_cloudwatch_log_group.auth.arn}:*",
            "${aws_cloudwatch_log_group.core.arn}:*",
            "${aws_cloudwatch_log_group.payment.arn}:*",
            "${aws_cloudwatch_log_group.notification.arn}:*",
            "${aws_cloudwatch_log_group.officer.arn}:*",
            "${aws_cloudwatch_log_group.admin.arn}:*",
            "${aws_cloudwatch_log_group.queue.arn}:*",
          ]
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
    )
  })
}

locals {
  all_secret_arns = concat(
    values(var.auth_secrets),
    values(var.core_secrets),
    values(var.payment_secrets),
    values(var.notification_secrets),
    values(var.officer_secrets),
    values(var.admin_secrets),
    values(var.queue_secrets),
  )

  base_environment = {
    DB_HOST     = var.db_address
    DB_PORT     = tostring(var.db_port)
    DB_NAME     = var.db_name
    VALKEY_HOST = var.valkey_host
    VALKEY_PORT = tostring(var.valkey_port)
  }

  shared_optional_environment = merge(
    var.sqs_notification_queue_url != "" ? { SQS_NOTIFICATION_URL = var.sqs_notification_queue_url } : {},
    var.s3_bucket_name != "" ? { S3_BUCKET = var.s3_bucket_name } : {},
    var.ses_domain != "" ? { SES_DOMAIN = var.ses_domain } : {},
  )

  auth_environment = merge(
    local.base_environment,
    local.shared_optional_environment,
    var.auth_extra_environment,
  )

  core_environment = merge(
    local.base_environment,
    local.shared_optional_environment,
    var.core_extra_environment,
  )

  payment_environment = merge(
    local.base_environment,
    local.shared_optional_environment,
    var.payment_extra_environment,
  )

  notification_environment = merge(
    local.base_environment,
    local.shared_optional_environment,
    var.notification_extra_environment,
  )

  officer_environment = merge(
    local.base_environment,
    local.shared_optional_environment,
    var.officer_extra_environment,
  )

  admin_environment = merge(
    local.base_environment,
    local.shared_optional_environment,
    var.admin_extra_environment,
  )

  queue_environment = merge(
    local.base_environment,
    local.shared_optional_environment,
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
  task_role_arn            = aws_iam_role.task.arn

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
      secrets     = [for k, v in var.auth_secrets : { name = k, valueFrom = v }]
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
  task_role_arn            = aws_iam_role.task.arn

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

resource "aws_ecs_task_definition" "payment" {
  family                   = "${var.project}-${var.environment}-payment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.payment_cpu)
  memory                   = tostring(var.payment_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

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
      secrets     = [for k, v in var.payment_secrets : { name = k, valueFrom = v }]
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
  task_role_arn            = aws_iam_role.task.arn

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
      secrets     = [for k, v in var.notification_secrets : { name = k, valueFrom = v }]
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
  task_role_arn            = aws_iam_role.task.arn

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
      secrets     = [for k, v in var.officer_secrets : { name = k, valueFrom = v }]
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
  task_role_arn            = aws_iam_role.task.arn

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
      secrets     = [for k, v in var.admin_secrets : { name = k, valueFrom = v }]
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
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name        = "queue"
      image       = var.queue_image
      essential   = true
      stopTimeout = 45
      portMappings = [
        { containerPort = var.queue_port, protocol = "tcp", name = "queue" }
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
      name        = "adot"
      image       = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
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
