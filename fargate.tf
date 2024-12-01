# CLUSTER

resource "aws_ecs_cluster" "this" {
  name = "${var.env_prefix}-${var.environment}"
}

# SERVICE

resource "aws_ecs_service" "this" {
  name             = "${var.env_prefix}-${var.environment}"
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  network_configuration {
    security_groups = [aws_security_group.alb.id, aws_security_group.efs.id]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.id
    container_name   = "${var.env_prefix}-${var.environment}-app"
    container_port   = var.container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

}

# TASK DEFINITION

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.env_prefix}-${var.environment}"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  container_definitions    = <<CONTAINER_DEFINITION
[
  {
    "secrets": [],
    "environment": [],
    "essential": true,
    "image": "${aws_ecr_repository.app_repository.repository_url}:latest",        
    "name": "${var.env_prefix}-${var.environment}-app",
    "portMappings": [
      {
        "containerPort": ${var.container_port}
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/dev/shared",
        "sourceVolume": "efs"
      }
    ],
    "logConfiguration": {
      "logDriver":"awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
CONTAINER_DEFINITION

  volume {
    name = "efs"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.this.id
    }
  }
}

# CLOUDWATCH

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.env_prefix}/${var.environment}/task"
  tags              = var.tags
  retention_in_days = var.log_retention_in_days
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "${var.env_prefix}-high-CPU-utilization-ecs-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.task_cpu_high_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
  alarm_name          = "${var.env_prefix}-low-CPU-utilization-ecs-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.task_cpu_low_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_in.arn]
}

# SCALING

resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_task
  min_capacity       = var.min_task
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_out" {
  name               = "${var.env_prefix}-ecs-scale-out-${var.environment}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scaling_out_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.scaling_out_adjustment
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in" {
  name               = "${var.env_prefix}-ecs-scale-in-${var.environment}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scaling_in_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = var.scaling_in_adjustment
    }
  }
}
