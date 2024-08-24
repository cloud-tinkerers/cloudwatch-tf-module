data "archive_file" "notifier" {
  type        = "zip"
  source_file = "${path.module}/code/notifier.py"
  output_path = "${path.module}/code/notifier.zip"
}

data "archive_file" "requests" {
  type        = "zip"
  source_dir  = "${path.module}/code/layers"
  output_path = "${path.module}/code/layer.zip"
}

resource "aws_lambda_function" "notifier" {
  filename         = "code/notifier.zip"
  function_name    = "alarm_notifier"
  handler          = "notifier.lambda_handler"
  role             = aws_iam_role.notifier_lambda.arn
  source_code_hash = data.archive_file.notifier.output_base64sha256
  runtime          = "python3.10"
  layers           = ["${aws_lambda_layer_version.notifier.arn}"]
  environment {
    variables = {
      discord_webhook = "${aws_ssm_parameter.discord_webhook.name}"
    }
  }
}

resource "aws_lambda_layer_version" "notifier" {
  filename            = data.archive_file.requests.output_path
  layer_name          = "requests"
  compatible_runtimes = ["python3.10", "python3.12"]
}

resource "aws_lambda_permission" "notifier" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.health_monitoring.arn
}