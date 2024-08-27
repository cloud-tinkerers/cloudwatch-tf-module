resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name                = "HighCPUUtilisation"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "This metric monitors ec2 cpu utilization"
  dimensions = {
    AutoScalingGroupName = data.aws_autoscaling_group.asg.name
  }
  alarm_actions = [aws_sns_topic.health_monitoring.arn]
}