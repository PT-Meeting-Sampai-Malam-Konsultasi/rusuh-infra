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

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "core_target_group_arn" {
  value = aws_lb_target_group.core.arn
}

output "queue_target_group_arn" {
  value = aws_lb_target_group.queue.arn
}

output "core_service_name" {
  value = aws_ecs_service.core.name
}

output "queue_service_name" {
  value = aws_ecs_service.queue.name
}

output "core_log_group_name" {
  value = aws_cloudwatch_log_group.core.name
}

output "queue_log_group_name" {
  value = aws_cloudwatch_log_group.queue.name
}
