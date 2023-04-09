resource "aws_ecs_service" "capacity_provider_test" {
  name                               = "capacity-provider-test"
  cluster                            = aws_ecs_cluster.capacity_provider_test.id
  task_definition                    = aws_ecs_task_definition.capacity_provider_test.arn
  scheduling_strategy                = "REPLICA"
  desired_count                      = 2
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_controller {
    type = "ECS"
  }

  enable_ecs_managed_tags = true

  health_check_grace_period_seconds = 120

  load_balancer {
    target_group_arn = aws_lb_target_group.capacity_provider_test.arn
    container_name   = "nginx"
    container_port   = 80
  }

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.capacity_provider_test.name
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

}

resource "aws_appautoscaling_target" "capacity_provider_test" {
  max_capacity       = 6
  min_capacity       = 3
  resource_id        = "service/${aws_ecs_cluster.capacity_provider_test.name}/${aws_ecs_service.capacity_provider_test.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "capacity_provider_test" {
  name               = "capacity-provider-test"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.capacity_provider_test.service_namespace
  resource_id        = aws_appautoscaling_target.capacity_provider_test.resource_id
  scalable_dimension = aws_appautoscaling_target.capacity_provider_test.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70
    scale_out_cooldown = 60
    scale_in_cooldown  = 300
  }

}

resource "aws_ecs_task_definition" "capacity_provider_test" {
  family       = "aws_ecs_task_definition"
  network_mode = "bridge"
  cpu          = 512
  memory       = 256

  container_definitions = <<TASK_DEFINITION
[
    {
        "name": "nginx",
        "image": "nginx:latest",
        "cpu": 512,
        "memory": 256,
        "portMappings": [
            {
                "containerPort": 80
            }
        ],
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${aws_cloudwatch_log_group.capacity_provider_test.name}",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "ecs"
            }
        }
    }
]
TASK_DEFINITION

}

resource "aws_cloudwatch_log_group" "capacity_provider_test" {
  name              = "/ecs/capacity-provider-test"
  retention_in_days = 14
}
