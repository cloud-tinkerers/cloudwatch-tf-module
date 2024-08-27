variable "client" {
  type = string
  description = "Name of the client"
}

variable "app" {
  type = string
  description = "The app in use"
}

variable "env" {
  type = string
  description = "The environment in use"
}

variable "region" {
    type = string
    description = "The AWS region being used."
}