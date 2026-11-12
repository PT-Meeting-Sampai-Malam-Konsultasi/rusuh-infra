# Queue alarms (NFR-09-Q2). Every alarm notifies the alarm topic on ALARM and
# on recovery. Metric alarms on the queue's own OTLP metrics come after this,
# once the ADOT EMF export shows their names and dimensions in CloudWatch.

locals {
  queue_alarm_prefix = "${var.project}-${var.environment}-queue"
  queue_tg_dimension = {
    TargetGroup  = var.queue_target_group_arn_suffix
    LoadBalancer = local.alb_dimension
  }

  # One metric filter + alarm per log line the queue writes when something
  # needs a person. The patterns match the JSON logs (LOG_FORMAT=json); the
  # messages are the exact slog messages in rusuh-queue.
  queue_log_alarms = {
    booking-dead-lettered = {
      message     = "booking event dead-lettered"
      metric      = "BookingDeadLettered"
      period      = 60
      evaluations = 1
      threshold   = 0
      description = "A booking event from core failed 5 times and moved to stream:booking:dlq; its lease is not released or held until it is replayed."
    }
    controller-stopped = {
      message     = "Background routine stopped"
      metric      = "BackgroundRoutineStopped"
      period      = 60
      evaluations = 1
      threshold   = 0
      description = "The admission controller (or another background routine) stopped on a task: that task no longer ticks, purges or reconciles."
    }
    held-leases-stuck = {
      message     = "held leases past their end"
      metric      = "HeldLeasesStuck"
      period      = 300
      evaluations = 1
      threshold   = 0
      description = "Leases held by core are past their end with no paid/expired event; their units stay out of stock until core resolves them."
    }
    admission-not-recorded = {
      message     = "admission not recorded in core"
      metric      = "AdmissionNotRecorded"
      period      = 300
      evaluations = 1
      threshold   = 2
      description = "Claims could not record the admission in core (POST /v1/core/admission), so those users cannot open Detail or pay."
    }
    tick-failing = {
      message     = "tick failed"
      metric      = "TickFailed"
      period      = 60
      evaluations = 3
      threshold   = 5
      description = "The controller's tick keeps failing (Valkey errors or a script fault): nobody is admitted while it lasts."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_running_tasks" {
  alarm_name          = "${local.queue_alarm_prefix}-no-running-task"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "No queue task is running: join, claim and the waiting room are down."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.queue_service_name
  }
  treat_missing_data = "breaching"

  tags = {
    Name = "${local.queue_alarm_prefix}-no-running-task"
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_unhealthy_hosts" {
  alarm_name          = "${local.queue_alarm_prefix}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "A queue target fails /readyz (PostgreSQL or Valkey unreachable, or the task is draining) for 3 minutes."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = local.queue_tg_dimension
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${local.queue_alarm_prefix}-unhealthy-targets"
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_5xx" {
  alarm_name          = "${local.queue_alarm_prefix}-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.queue_alarm_5xx_threshold
  alarm_description   = "The queue answers 5xx above the threshold in 5 minutes (503 VERIFICATION_UNAVAILABLE counts too: core's keys or Valkey are failing)."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = local.queue_tg_dimension
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${local.queue_alarm_prefix}-5xx"
  }
}

resource "aws_cloudwatch_log_metric_filter" "queue" {
  for_each = local.queue_log_alarms

  name           = "${local.queue_alarm_prefix}-${each.key}"
  log_group_name = var.queue_log_group_name
  pattern        = "{ $.msg = \"${each.value.message}\" }"

  metric_transformation {
    name      = each.value.metric
    namespace = "Rusuh/Queue"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_log" {
  for_each = local.queue_log_alarms

  alarm_name          = "${local.queue_alarm_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.evaluations
  metric_name         = aws_cloudwatch_log_metric_filter.queue[each.key].metric_transformation[0].name
  namespace           = "Rusuh/Queue"
  period              = each.value.period
  statistic           = "Sum"
  threshold           = each.value.threshold
  alarm_description   = each.value.description
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${local.queue_alarm_prefix}-${each.key}"
  }
}
