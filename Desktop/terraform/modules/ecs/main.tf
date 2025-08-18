locals {
  services_map        = { for s in var.services : s.name => s }
  sorted_names        = sort(keys(local.services_map))
  active_listener_arn = coalesce(var.https_listener_arn, var.http_listener_arn)
}

resource "aws_ecs_cluster" "this" { name = var.cluster_name }

# IAM
data "aws_iam_policy_document" "assume_task" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["ecs-tasks.amazonaws.com"] }
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

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# SSM 최소권한 (선택)
data "aws_iam_policy_document" "ssm_read" {
  count = length(var.ssm_parameter_paths) > 0 ? 1 : 0
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = [for p in var.ssm_parameter_paths :
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${p}"
    ]
  }
}

resource "aws_iam_policy" "ssm_read" {
  count       = length(var.ssm_parameter_paths) > 0 ? 1 : 0
  name        = "${var.name}-ecs-ssm-read"
  description = "Allow ECS tasks to read specific SSM parameters"
  policy      = data.aws_iam_policy_document.ssm_read[0].json
}

resource "aws_iam_role_policy_attachment" "attach_ssm_read" {
  count      = length(var.ssm_parameter_paths) > 0 ? 1 : 0
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.ssm_read[0].arn
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_task.json
}

# 서비스별 리소스
resource "aws_cloudwatch_log_group" "svc" {
  for_each = local.services_map
  name              = "/ecs/${each.key}"
  retention_in_days = 14
}

resource "aws_lb_target_group" "svc" {
  for_each    = local.services_map
  name        = substr("${var.name}-${each.key}", 0, 32)
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.target_group_vpc_id
  target_type = "ip"
  health_check {
    path                = each.value.health_path
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    matcher             = "200-399"
  }
}

# 각 서비스용 SG (ALB만 인바운드)
resource "aws_security_group" "svc" {
  for_each = local.services_map
  name     = "${var.name}-${each.key}-sg"
  vpc_id   = var.vpc_id

  ingress {
    from_port       = each.value.container_port
    to_port         = each.value.container_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
    description     = "From ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB 접근 허용: 서비스 SG → DB SG (5432)
resource "aws_security_group_rule" "db_from_services" {
  for_each = local.services_map
  type              = "Ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = var.db_sg_id
  source_security_group_id = aws_security_group.svc[each.key].id
  description       = "Allow Postgres from ${each.key}"
}

resource "aws_ecs_task_definition" "svc" {
  for_each               = local.services_map
  family                 = each.key
  cpu                    = each.value.cpu
  memory                 = each.value.memory
  network_mode           = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn     = aws_iam_role.task_execution.arn
  task_role_arn          = aws_iam_role.task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = each.key
    image     = each.value.image
    essential = true
    portMappings = [{
      containerPort = each.value.container_port
      hostPort      = each.value.container_port
      protocol      = "tcp"
    }]
    environment = [ for k, v in each.value.env : { name = k, value = v } ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.svc[each.key].name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = each.key
      }
    }
    # 컨테이너 내부 헬스체크는 이미지에 curl 미포함 시 실패하므로 생략
  }])
}

resource "aws_ecs_service" "svc" {
  for_each              = local.services_map
  name                  = each.key
  cluster               = aws_ecs_cluster.this.id
  task_definition       = aws_ecs_task_definition.svc[each.key].arn
  desired_count         = each.value.desired_count
  launch_type           = "FARGATE"
  force_new_deployment  = true

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.svc[each.key].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svc[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }

  lifecycle { ignore_changes = [desired_count] }
  depends_on = [aws_lb_target_group.svc]
}

# Path 기반 Listener Rule
resource "aws_lb_listener_rule" "svc" {
  for_each     = local.services_map
  listener_arn = local.active_listener_arn
  priority     = 100 + index(local.sorted_names, each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc[each.key].arn
  }

  condition { path_pattern { values = [each.value.path] } }
}
