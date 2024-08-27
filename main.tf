locals {
  default_tags = {
    terraform   = "true"
    environment = "${var.env}"
    client      = "${var.client}"
    application = "${var.app}"
  }
}

data "aws_autoscaling_group" "asg" {
  name = "${var.client}-${var.app}-${var.env}-asg"
}

data "aws_db_instance" "rds" {
  db_instance_identifier = "${var.client}-${var.app}-${var.env}"
}