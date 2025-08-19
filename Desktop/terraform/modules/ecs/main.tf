locals {
  services_map = { for s in var.services : s.name => s }
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

# IAM (AssumeRole)
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
}

resource "aws_iam_role_policy_attachment" "exec_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_task.json
}

# ECS 서비스용 공용 SG (모든 서비스가 이 SG 사용)
resource "aws_security_group" "ecs" {
  name   = "${var.name}-ecs-sg"
  vpc_id = var.vpc_id

  # 인바운드 규칙 없음 (내부 통신만, 필요시 나중에 추가)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-ecs-sg" }
}

# DB 인바운드: ECS SG → DB SG (5432)
resource "aws_security_group_rule" "db_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.db_sg_id
  source_security_group_id = aws_security_group.ecs.id
  description              = "Allow Postgres from ECS services"
}

# 서비스별 로그 그룹
resource "aws_cloudwatch_log_group" "svc" {
  for_each = local.services_map
  name              = "/ecs/${each.key}"
  retention_in_days = 14
}

data "aws_region" "current" {}

# Task Definitions
resource "aws_ecs_task_definition" "svc" {
  for_each                 = local.services_map
  family                   = each.key
  cpu                      = tostring(each.value.cpu)
  memory                   = tostring(each.value.memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true

      portMappings = [{
        containerPort = each.value.container_port
        hostPort      = each.value.container_port
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
}

# ECS Services (내부 전용, 퍼블릭 IP 없음)
resource "aws_ecs_service" "svc" {
  for_each             = local.services_map
  name                 = each.key
  cluster              = aws_ecs_cluster.this.id
  task_definition      = aws_ecs_task_definition.svc[each.key].arn
  desired_count        = each.value.desired_count
  launch_type          = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  lifecycle { ignore_changes = [desired_count] }
}
