data "aws_iam_policy" "lambda_execution" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "read_parameter" {
  statement {
    actions = [
        "ssm:GetParameter",
        "ssm:GetParameters"
    ]
    resources = ["${aws_ssm_parameter.discord_webhook.arn}"]
  }
}

resource "aws_iam_policy" "read_parameter" {
  name = "read-ssm-parameter"
  path = "/"
  policy = data.aws_iam_policy_document.read_parameter.json
}

resource "aws_iam_role" "notifier_lambda" {
  name = "notifier_lambda"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
        {
            "Action" : "sts:AssumeRole",
            "Effect" : "Allow",
            "Principal" : {
                "Service" : [
                    "lambda.amazonaws.com"
                ]
            }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.notifier_lambda.name
  policy_arn = data.aws_iam_policy.lambda_execution.arn
}

resource "aws_iam_role_policy_attachment" "read_parameter" {
  role       = aws_iam_role.notifier_lambda.name
  policy_arn = aws_iam_policy.read_parameter.arn
}