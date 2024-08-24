locals {
  default_tags = {
    terraform   = "true"
    environment = "${var.env}"
    client      = "${var.client}"
    application = "${var.app}"
  }
}