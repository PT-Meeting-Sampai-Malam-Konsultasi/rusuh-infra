output "dashboard_name" {
  value = aws_cloudwatch_dashboard.overview.dashboard_name
}

output "alb_5xx_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.arn
}

output "dlq_alarm_arns" {
  value = { for k, a in aws_cloudwatch_metric_alarm.dlq_depth : k => a.arn }
}
