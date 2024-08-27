// Re-usable requests layer
data "archive_file" "requests" {
  type        = "zip"
  source_dir  = "${path.module}/code/layers"
  output_path = "${path.module}/code/layer.zip"
}

resource "aws_lambda_layer_version" "requests" {
  filename            = data.archive_file.requests.output_path
  layer_name          = "requests"
  compatible_runtimes = ["python3.10", "python3.12"]
}

// Notifier function
data "archive_file" "notifier" {
  type        = "zip"
  source_file = "${path.module}/code/notifier.py"
  output_path = "${path.module}/code/notifier.zip"
}

resource "aws_lambda_function" "notifier" {
  filename         = "${path.module}/code/notifier.zip"
  function_name    = "alarm_notifier"
  handler          = "notifier.lambda_handler"
  role             = aws_iam_role.general_lambda.arn
  source_code_hash = data.archive_file.notifier.output_base64sha256
  runtime          = "python3.10"
  layers           = ["${aws_lambda_layer_version.requests.arn}"]
  timeout          = 30
  environment {
    variables = {
      discord_webhook = "${aws_ssm_parameter.discord_webhook.name}"
    }
  }
}

resource "aws_lambda_permission" "notifier" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.health_monitoring.arn
}

// Report function
data "archive_file" "health_report" {
  type        = "zip"
  source_file = "${path.module}/code/health_report.py"
  output_path = "${path.module}/code/health_report.zip"
}

resource "aws_lambda_function" "health_report" {
  filename         = "${path.module}/code/health_report.zip"
  function_name    = "health_report"
  handler          = "health_report.lambda_handler"
  role             = aws_iam_role.general_lambda.arn
  source_code_hash = data.archive_file.health_report.output_base64sha256
  runtime          = "python3.10"
  layers           = ["${aws_lambda_layer_version.requests.arn}"]
  timeout          = 30
  environment {
    variables = {
      discord_webhook = "${aws_ssm_parameter.discord_webhook.name}"
      ASG_NAME = "${data.aws_autoscaling_group.asg.name}"
      RDS_ID = "${data.aws_db_instance.rds.db_instance_identifier}"
      REGION = "${var.region}"
    }
  }
}

resource "aws_lambda_permission" "health_report" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_report.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.health_report.arn
}