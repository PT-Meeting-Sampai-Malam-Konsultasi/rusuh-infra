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

# SNS topic for alarm notifications (Tier 2). Always created: the alert
# endpoint is mandatory (alarm_email is a required variable). The
# recipient must confirm the subscription via the email AWS sends after
# apply, or notifications are not delivered.
resource "aws_sns_topic" "alarms" {
  name = "${var.project}-${var.environment}-alarms"

  tags = {
    Name = "${var.project}-${var.environment}-alarms"
  }
}

resource "aws_sns_topic_subscription" "alarms_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
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
  alarm_actions       = [aws_sns_topic.alarms.arn]
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
  alarm_actions       = [aws_sns_topic.alarms.arn]
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

# ---------------------------------------------------------------------------
# CloudTrail (Tier 3: audit). Account-wide API audit trail with log file
# validation, delivered to a dedicated S3 bucket. OPT-IN (default off):
# the account already has the baseline multi-region trail
# "soldev-lz-trail", so creating a second multi-region trail here would
# duplicate every event and its cost. Enable only if this environment
# needs its own trail in addition to the baseline (set
# enable_cloudtrail = true).
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "${var.project}-${var.environment}-cloudtrail-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project}-${var.environment}-cloudtrail"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
    ]
  })
}

resource "aws_cloudtrail" "this" {
  count                         = var.enable_cloudtrail ? 1 : 0
  name                          = "${var.project}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  tags = {
    Name = "${var.project}-${var.environment}-trail"
  }
}
