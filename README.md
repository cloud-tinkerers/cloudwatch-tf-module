# cloudwatch-tf-module

This module:

* sets up a log group for the main ECS service to use
* sets up an SNS topic for cloudwatch alarms to trigger
* sets up a cloudwatch alarm for high CPU on the ASG
* sets up a lambda function that is triggered by the SNS topic

The lambda function takes the incoming event and posts a request to the discord webhook, this sends an alert to the monitoring channel.

The discord webhook URL is kept in the parameter store which the lambda pulls from.