output "scheduler_role_arn" {
  description = "IAM role assumed by EventBridge Scheduler for ECS and RDS cost actions."
  value       = aws_iam_role.scheduler.arn
}
