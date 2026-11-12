output "dashboard_name" {
  value = aws_cloudwatch_dashboard.overview.dashboard_name
}

output "alb_5xx_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.arn
}

output "dlq_alarm_arns" {
  value = { for k, a in aws_cloudwatch_metric_alarm.dlq_depth : k => a.arn }
}

output "alarm_topic_arn" {
  value = aws_sns_topic.alarms.arn
}

output "queue_alarm_arns" {
  value = merge(
    {
      running_tasks   = aws_cloudwatch_metric_alarm.queue_running_tasks.arn
      unhealthy_hosts = aws_cloudwatch_metric_alarm.queue_unhealthy_hosts.arn
      target_5xx      = aws_cloudwatch_metric_alarm.queue_5xx.arn
    },
    { for k, a in aws_cloudwatch_metric_alarm.queue_log : k => a.arn },
  )
}
