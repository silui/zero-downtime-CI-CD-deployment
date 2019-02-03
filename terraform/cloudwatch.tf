resource "aws_cloudwatch_metric_alarm" "High" {
  alarm_name                = "High_cpu_alert"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  dimensions = {
  AutoScalingGroupName = "${aws_autoscaling_group.example-autoscaling.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.High_policy.arn}"]
}

resource "aws_autoscaling_policy" "High_policy" {
  name                   = "High_policy"
  scaling_adjustment     = 6
  adjustment_type        = "ExactCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.example-autoscaling.name}"
}



resource "aws_cloudwatch_metric_alarm" "Low" {
  alarm_name                = "Low_cpu_alert"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "30"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  dimensions = {
  AutoScalingGroupName = "${aws_autoscaling_group.example-autoscaling.name}"
  }
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.Low_policy.arn}"]
}

resource "aws_autoscaling_policy" "Low_policy" {
  name                   = "Low_policy"
  scaling_adjustment     = 2
  adjustment_type        = "ExactCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.example-autoscaling.name}"
}
