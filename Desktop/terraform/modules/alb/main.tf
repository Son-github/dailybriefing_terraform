locals {
  sorted = sort(keys(var.routes))  # 우선순위 계산용
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
  idle_timeout       = 60
  tags               = { Name = "${var.name}-alb" }
}

resource "aws_lb_target_group" "svc" {
  for_each    = var.routes

  name        = substr("${var.name}-${each.key}", 0, 32)
  port        = each.value.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = { Name = "${var.name}-${each.key}-tg" }
}

# 80 리스너는 항상 생성
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # 인증서가 없으면 80에서 고정응답(404)
  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }

  # 인증서가 있으면 443으로 리다이렉트
  dynamic "default_action" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# 443 리스너는 인증서 있을 때만 생성
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn == null ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# 규칙을 붙일 리스너 선택(HTTPS가 있으면 HTTPS, 없으면 HTTP)
locals {
  listener_arn = try(aws_lb_listener.https[0].arn, aws_lb_listener.http.arn)
}

resource "aws_lb_listener_rule" "paths" {
  for_each     = var.routes
  listener_arn = local.listener_arn
  priority     = 100 + index(local.sorted, each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc[each.key].arn
  }

  condition {
    path_pattern { values = [each.value.path] }
  }
}


