resource "aws_sqs_queue" "dlq" {
  for_each = var.queues

  name                      = "${var.project}-${var.environment}-${each.key}-dlq"
  message_retention_seconds = each.value.message_retention_seconds

  tags = {
    Name = "${var.project}-${var.environment}-${each.key}-dlq"
  }
}

resource "aws_sqs_queue" "main" {
  for_each = var.queues

  name                       = "${var.project}-${var.environment}-${each.key}"
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = each.value.max_receive_count
  })

  tags = {
    Name = "${var.project}-${var.environment}-${each.key}"
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  for_each = var.queues

  queue_url = aws_sqs_queue.dlq[each.key].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main[each.key].arn]
  })
}
