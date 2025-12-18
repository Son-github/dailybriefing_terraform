data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ✅ 추가: Secrets Manager에서 시크릿 읽기 권한 (최소)
data "aws_iam_policy_document" "ecs_exec_extra" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_exec_extra" {
  name   = "${var.name}-ecs-exec-extra"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.ecs_exec_extra.json
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

locals {
  merged_env = {
    for k, svc in var.services :
    k => merge(var.common_env, try(svc.env, {}))
  }
}

# ✅ Secrets Manager (name 기반 조회)
data "aws_secretsmanager_secret" "common" {
  for_each = var.common_secrets
  name     = each.value
}

resource "aws_ecs_task_definition" "svc" {
  for_each = var.services

  family                   = "${var.name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(each.value.cpu)
  memory                   = tostring(each.value.memory)
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true

      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for ek, ev in local.merged_env[each.key] :
        { name = ek, value = ev }
      ]

      # ✅ SecretsManager → 컨테이너 ENV 주입
      secrets = [
        for env_name, secret_name in var.common_secrets : {
          name      = env_name
          valueFrom = data.aws_secretsmanager_secret.common[env_name].arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = each.key
        }
      }
    }
  ])
}

resource "aws_ecs_service" "svc" {
  for_each = var.services

  name            = "${var.name}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.svc[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  # ✅ 추가: Spring 부팅 시간 고려 (ALB 헬스체크로 바로 죽는 것 방지)
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arns[each.key]
    container_name   = each.key
    container_port   = each.value.container_port
  }
}
