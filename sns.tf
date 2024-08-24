resource "aws_sns_topic" "health_monitoring" {
  name = "Health-monitoring"
}

resource "aws_sns_topic_subscription" "health_monitoring" {
  topic_arn = aws_sns_topic.health_monitoring.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notifier.arn
}