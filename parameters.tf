// Value set to null to avoid commiting secret to code
resource "aws_ssm_parameter" "discord_webhook" {
  name = "discord_webhook"
  type = "SecureString"
  value = "null"
  lifecycle {
    ignore_changes = [ value ]
  }
}