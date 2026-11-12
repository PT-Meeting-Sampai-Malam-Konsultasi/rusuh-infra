output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_security_group_ids" {
  description = "Per-service security group IDs (service name -> ID). Pass values() to the data module."
  value       = local.service_security_group_ids
}

output "service_connect_namespace" {
  value = aws_service_discovery_http_namespace.this.name
}

output "service_connect_namespace_arn" {
  value = aws_service_discovery_http_namespace.this.arn
}

output "core_target_group_arn" {
  value = aws_lb_target_group.core.arn
}

output "queue_target_group_arn" {
  value = aws_lb_target_group.queue.arn
}

output "queue_target_group_arn_suffix" {
  value = aws_lb_target_group.queue.arn_suffix
}

output "auth_target_group_arn" {
  value = aws_lb_target_group.auth.arn
}

output "payment_target_group_arn" {
  value = aws_lb_target_group.payment.arn
}

output "officer_target_group_arn" {
  value = aws_lb_target_group.officer.arn
}

output "admin_target_group_arn" {
  value = aws_lb_target_group.admin.arn
}

output "service_arns" {
  description = "ECS service ARNs keyed by service name."
  value = {
    auth          = aws_ecs_service.auth.id
    core          = aws_ecs_service.core.id
    payment       = aws_ecs_service.payment.id
    notification  = aws_ecs_service.notification.id
    officer       = aws_ecs_service.officer.id
    admin         = aws_ecs_service.admin.id
    queue         = aws_ecs_service.queue.id
    dukcapil-mock = aws_ecs_service.dukcapil_mock.id
  }
}

output "service_desired_counts" {
  description = "Configured desired counts keyed by service name."
  value = {
    auth         = var.auth_desired_count
    core         = var.core_desired_count
    payment      = var.payment_desired_count
    notification = var.notification_desired_count
    officer      = var.officer_desired_count
    admin        = var.admin_desired_count
    queue        = var.queue_desired_count
  }
}

output "core_service_name" {
  value = aws_ecs_service.core.name
}

output "queue_service_name" {
  value = aws_ecs_service.queue.name
}

output "auth_service_name" {
  value = aws_ecs_service.auth.name
}

output "payment_service_name" {
  value = aws_ecs_service.payment.name
}

output "notification_service_name" {
  value = aws_ecs_service.notification.name
}

output "officer_service_name" {
  value = aws_ecs_service.officer.name
}

output "admin_service_name" {
  value = aws_ecs_service.admin.name
}

output "core_log_group_name" {
  value = aws_cloudwatch_log_group.core.name
}

output "queue_log_group_name" {
  value = aws_cloudwatch_log_group.queue.name
}

output "queue_metrics_log_group_name" {
  value = aws_cloudwatch_log_group.queue_metrics.name
}

output "auth_log_group_name" {
  value = aws_cloudwatch_log_group.auth.name
}

output "payment_log_group_name" {
  value = aws_cloudwatch_log_group.payment.name
}

output "notification_log_group_name" {
  value = aws_cloudwatch_log_group.notification.name
}

output "officer_log_group_name" {
  value = aws_cloudwatch_log_group.officer.name
}

output "admin_log_group_name" {
  value = aws_cloudwatch_log_group.admin.name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs per service (CD copies release images from GHCR into these)."
  value = {
    auth         = aws_ecr_repository.auth.repository_url
    core         = aws_ecr_repository.core.repository_url
    payment      = aws_ecr_repository.payment.repository_url
    notification = aws_ecr_repository.notification.repository_url
    officer      = aws_ecr_repository.officer.repository_url
    admin        = aws_ecr_repository.admin.repository_url
    queue        = aws_ecr_repository.queue.repository_url
  }
}

output "deploy_role_arn" {
  description = "GitHub OIDC deploy role ARN (assumed by the backend CD workflow)."
  value       = aws_iam_role.deploy.arn
}
