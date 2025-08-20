locals {
  svc = var.services
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

# IAM
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
  name               = "${var.name}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_task.json
  tags = { Name = "${var.name}-ecs-exec" }
}

resource "aws_iam_role_policy_attachment" "exec_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.assume_task.json
  tags = { Name = "${var.name}-ecs-task" }
}

# SG: ECS 태스크용 (아웃바운드만 허용)
resource "aws_security_group" "ecs" {
  name   = "${var.name}-ecs-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-ecs-sg" }
}

# DB 인바운드: ECS SG -> DB SG (5432)
resource "aws_security_group_rule" "db_ingress" {
  count                   = local.use_db ? 1 : 0
  type                    = "ingress"
  from_port               = 5432
  to_port                 = 5432
  protocol                = "tcp"
  security_group_id       = var.db_sg_id
  source_security_group_id= aws_security_group.ecs.id
  description             = "Postgres from ECS"
}

# 로그 그룹
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

  container_definitions = jsonencode([{
    name      = each.key
    image     = each.value.image
    essential = true
    portMappings = [{
      containerPort = tonumber(each.value.container_port)
      hostPort      = tonumber(each.value.container_port)
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
  }])
}

# (옵션) ALB가 켜진 경우: TG, Listener Rule
resource "aws_lb_target_group" "svc" {
  for_each    = var.enable_alb ? local.svc : {}
  name        = substr("${var.name}-${each.key}", 0, 32)
  port        = tonumber(each.value.container_port)
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Fargate는 ip 타겟
  health_check {
    path                = length(each.value.path) > 0 ? replace(each.value.path, "/*", "/") : "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    matcher {
      http_code = "200-399"
    }
  }
}

resource "aws_lb_listener_rule" "svc" {
  for_each     = var.enable_alb ? local.svc : {}
  listener_arn = var.alb_listener_arn
  priority     = 100 + index(sort(keys(local.svc)), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc[each.key].arn
  }

  condition {
    path_pattern {
      values = [length(each.value.path) > 0 ? each.value.path : "/*"]
    }
  }
}

# ECS Service (프라이빗 서브넷, 퍼블릭IP 없음)
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
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.svc[each.key].arn
      container_name   = each.key
      container_port   = tonumber(each.value.container_port)
    }
  }

  lifecycle { ignore_changes = [desired_count] }
}
