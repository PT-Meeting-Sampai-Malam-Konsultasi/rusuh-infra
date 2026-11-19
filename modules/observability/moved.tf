moved {
  from = aws_sns_topic_subscription.alarms_email
  to   = aws_sns_topic_subscription.alarms_email["edy_supardi@telkomsel.co.id"]
}
