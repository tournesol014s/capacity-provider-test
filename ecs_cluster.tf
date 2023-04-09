resource "aws_ecs_cluster" "capacity_provider_test" {
  name = "capacity-provider-test"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "capacity_provider_test" {
  cluster_name = aws_ecs_cluster.capacity_provider_test.name

  capacity_providers = [aws_ecs_capacity_provider.capacity_provider_test.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.capacity_provider_test.name
  }
}

resource "aws_ecs_capacity_provider" "capacity_provider_test" {
  name = "capacity-provider-test"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.capacity_provider_test.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      instance_warmup_period    = 60
      maximum_scaling_step_size = 3
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 90
    }
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
  name                  = "capacity-provider-test"
  vpc_zone_identifier   = [aws_subnet.private_1a[0].id, aws_subnet.private_1c[0].id, aws_subnet.private_1d[0].id]
  desired_capacity      = 1
  max_size              = 3
  min_size              = 1
  protect_from_scale_in = true
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

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

data "aws_ssm_parameter" "ecs_optimized_ami_image_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}
