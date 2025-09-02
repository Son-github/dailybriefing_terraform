locals {
  svc = var.services
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

data "aws_iam_policy_document" "assume_task" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name}-ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_task.json

  tags = {
    Name = "${var.name}-ecs-task-exec-role"
  }
}

resource "aws_iam_role_policy_attachment" "exec_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_task.json

  tags = {
    Name = "${var.name}-ecs-task-role"
  }
}

# ⚠️ DB 인바운드 규칙은 VPC 모듈에서 관리합니다 (여기서 제거)

resource "aws_cloudwatch_log_group" "svc" {
  for_each = local.svc

  name              = "/ecs/${each.key}"
  retention_in_days = var.cloudwatch_retention_days
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "svc" {
  for_each                 = local.svc
  family                   = each.key
  cpu                      = tostring(each.value.cpu)
  memory                   = tostring(each.value.memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true

      portMappings = [{
        containerPort = tonumber(each.value.container_port)
        hostPort      = tonumber(each.value.container_port)
        protocol      = "tcp"
      }]

      environment = [
        for k, v in each.value.env : { name = k, value = v }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.svc[each.key].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = each.key
        }
      }
    }
  ])

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "svc" {
  for_each             = local.svc
  name                 = each.key
  cluster              = aws_ecs_cluster.this.id
  task_definition      = aws_ecs_task_definition.svc[each.key].arn
  desired_count        = tonumber(each.value.desired_count)
  launch_type          = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = lookup(var.target_group_arns, each.key, null) == null ? [] : [1]
    content {
      target_group_arn = var.target_group_arns[each.key]
      container_name   = each.key
      container_port   = tonumber(each.value.container_port)
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# (옵션) 오토스케일
resource "aws_appautoscaling_target" "svc" {
  for_each = var.enable_autoscaling ? local.svc : {}

  max_capacity       = var.autoscaling.max_capacity
  min_capacity       = var.autoscaling.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.svc]
}

resource "aws_appautoscaling_policy" "svc_cpu" {
  for_each = var.enable_autoscaling ? local.svc : {}

  name               = "${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.svc[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.svc[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.svc[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling.target_cpu

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
