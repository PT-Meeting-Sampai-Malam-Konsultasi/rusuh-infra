locals {
  alb_dimension  = join("/", slice(split("/", var.alb_arn), 1, 4))
  dashboard_name = var.dashboard_name != "" ? var.dashboard_name : "${var.project}-${var.environment}-overview"

  widget_alb = {
    type   = "metric"
    x      = 0
    y      = 0
    width  = 12
    height = 6
    properties = {
      title = "ALB requests + 5xx"
      metrics = [
        ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_dimension, { stat = "Sum", period = 300 }],
        ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_dimension, { stat = "Sum", period = 300 }],
      ]
      region = var.region
      view   = "timeSeries"
    }
  }

  widget_ecs = {
    type   = "metric"
    x      = 12
    y      = 0
    width  = 12
    height = 6
    properties = {
      title = "ECS CPU / memory"
      metrics = [
        ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.core_service_name, { stat = "Average", period = 300 }],
        ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.core_service_name, { stat = "Average", period = 300 }],
        ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.queue_service_name, { stat = "Average", period = 300 }],
        ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.queue_service_name, { stat = "Average", period = 300 }],
      ]
      region = var.region
      view   = "timeSeries"
    }
  }

  widget_dlq = {
    type   = "metric"
    x      = 0
    y      = 6
    width  = 24
    height = 6
    properties = {
      title = "DLQ depth (must stay 0)"
      metrics = [
        for name, arn in var.dlq_queue_arns : [
          "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", element(split(":", arn), 5), { stat = "Maximum", period = 300 }
        ]
      ]
      region = var.region
      view   = "timeSeries"
    }
  }

  widgets = concat(
    [local.widget_alb, local.widget_ecs],
    length(var.dlq_queue_arns) > 0 ? [local.widget_dlq] : [],
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_5xx_evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_5xx_period
  statistic           = "Sum"
  threshold           = var.alarm_5xx_threshold
  alarm_description   = "ALB target 5xx above threshold (demo)"
  dimensions = {
    LoadBalancer = local.alb_dimension
  }
  treat_missing_data = "notBreaching"

  tags = {
    Name = "${var.project}-${var.environment}-alb-5xx"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  for_each = var.dlq_queue_arns

  alarm_name          = "${var.project}-${var.environment}-dlq-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "DLQ ${each.key} is non-empty (should stay empty)"
  dimensions = {
    QueueName = element(split(":", each.value), 5)
  }
  treat_missing_data = "notBreaching"

  tags = {
    Name = "${var.project}-${var.environment}-dlq-${each.key}"
  }
}

resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = local.dashboard_name
  dashboard_body = jsonencode({ widgets = local.widgets })
}
