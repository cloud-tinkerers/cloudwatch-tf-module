resource "aws_scheduler_schedule" "health_report" {
  name = "health_report_schedule"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression_timezone = "Europe/London"
  schedule_expression          = "cron(0 10 ? * SAT *)"

  target {
    arn      = aws_lambda_function.health_report.arn
    role_arn = aws_iam_role.health_report_event.arn
  }
}

resource "aws_iam_role" "health_report_event" {
  name = "health_report_scheduler_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["scheduler.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy" "AmazonEventBridgeSchedulerFullAccess" {
  name = "AmazonEventBridgeSchedulerFullAccess"
}

data "aws_iam_policy_document" "invoke_lambda" {
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = ["${aws_lambda_function.health_report.arn}"]
  }
}

resource "aws_iam_policy" "invoke_lambda" {
  name = "invoke_lambda"
  policy = data.aws_iam_policy_document.invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "scheduler_access" {
  policy_arn = data.aws_iam_policy.AmazonEventBridgeSchedulerFullAccess.arn
  role       = aws_iam_role.health_report_event.name
}

resource "aws_iam_role_policy_attachment" "invoke_lambda" {
  policy_arn = aws_iam_policy.invoke_lambda.arn
  role       = aws_iam_role.health_report_event.name
}