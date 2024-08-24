resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${var.client}-${var.env}-log-group"
  retention_in_days = 14

  tags = local.default_tags
}