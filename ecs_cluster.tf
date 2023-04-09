resource "aws_ecs_cluster" "capacity_provider_test" {
  name = "capacity-provider-test"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_launch_template" "capacity_provider_test" {
  name          = "capacity-provider-test"
  image_id      = data.aws_ssm_parameter.ecs_optimized_ami_image_id.value
  instance_type = "t3.micro"
  user_data     = base64encode(templatefile("userdata/ecs_cluster.sh", { cluster_name = aws_ecs_cluster.capacity_provider_test.name }))
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_role.arn
  }
  vpc_security_group_ids = [aws_security_group.ecs_service.id]
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = "gp3"
      volume_size = 30
    }
  }

}

resource "aws_autoscaling_group" "capacity_provider_test" {
  name                = "capacity-provider-test"
  vpc_zone_identifier = [aws_subnet.private_1a[0].id, aws_subnet.private_1c[0].id, aws_subnet.private_1d[0].id]
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.capacity_provider_test.id
        version            = "$Latest"
      }

      override {
        instance_type = "t3.micro"
      }

      override {
        instance_type = "t3a.micro"
      }
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

data "aws_ssm_parameter" "ecs_optimized_ami_image_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_autoscaling_policy" "capacity_provider_test_scale_out_cpu" {
  name                   = "capacity-provider-test-scale-out-cpu"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.capacity_provider_test.name
}

resource "aws_autoscaling_policy" "capacity_provider_test_scale_in_cpu" {
  name                   = "capacity-provider-test-scale-in-cpu"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.capacity_provider_test.name
}

resource "aws_cloudwatch_metric_alarm" "capacity_provider_test_cpu_high" {
  alarm_name          = "capacity-provider-test-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  dimensions = {
    ClusterName = aws_ecs_cluster.capacity_provider_test.name
  }
  alarm_actions = ["${aws_autoscaling_policy.capacity_provider_test_scale_out_cpu.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "capacity-provider-test-cpu-low" {
  alarm_name          = "capacity-provider-test-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  dimensions = {
    ClusterName = aws_ecs_cluster.capacity_provider_test.name
  }
  alarm_actions = ["${aws_autoscaling_policy.capacity_provider_test_scale_in_cpu.arn}"]
}
