data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "scheduler" {
  name = "${var.project}-${var.environment}-cost-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-${var.environment}-cost-scheduler"
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${var.project}-${var.environment}-cost-scheduler"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService"]
        Resource = values(var.service_arns)
      },
      {
        Effect   = "Allow"
        Action   = ["rds:StartDBInstance", "rds:StopDBInstance"]
        Resource = ["arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db/${var.db_instance_identifier}"]
      },
    ]
  })
}

locals {
  service_actions = merge(
    {
      for service, desired_count in var.weekday_service_desired_counts : "start-${service}" => {
        expression = "cron(0 6 ? * MON-FRI *)"
        input = {
          Cluster      = var.ecs_cluster_name
          Service      = service
          DesiredCount = desired_count
        }
      }
    },
    {
      for service in keys(var.weekday_service_desired_counts) : "stop-weekday-${service}" => {
        expression = "cron(0 0 ? * TUE-FRI *)"
        input = {
          Cluster      = var.ecs_cluster_name
          Service      = service
          DesiredCount = 0
        }
      }
    },
    {
      for service in keys(var.weekday_service_desired_counts) : "stop-weekend-${service}" => {
        expression = "cron(1 0 ? * SAT *)"
        input = {
          Cluster      = var.ecs_cluster_name
          Service      = service
          DesiredCount = 0
        }
      }
    },
  )

  rds_actions = {
    start = {
      expression = "cron(45 5 ? * MON-FRI *)"
      target_arn = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    }
    stop_weekday = {
      expression = "cron(15 0 ? * TUE-FRI *)"
      target_arn = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    }
    stop_weekend = {
      expression = "cron(15 0 ? * SAT *)"
      target_arn = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    }
  }
}

resource "aws_scheduler_schedule" "ecs" {
  for_each = local.service_actions

  name                         = "${var.project}-${var.environment}-ecs-${each.key}"
  schedule_expression          = each.value.expression
  schedule_expression_timezone = "Asia/Jakarta"
  state                        = var.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode(each.value.input)
  }
}

resource "aws_scheduler_schedule" "rds" {
  for_each = local.rds_actions

  name                         = "${var.project}-${var.environment}-rds-${each.key}"
  schedule_expression          = each.value.expression
  schedule_expression_timezone = "Asia/Jakarta"
  state                        = var.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = each.value.target_arn
    role_arn = aws_iam_role.scheduler.arn
    input = jsonencode({
      DbInstanceIdentifier = var.db_instance_identifier
    })
  }
}
