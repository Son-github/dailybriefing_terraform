resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  tags               = { Name = "${var.name}-alb" }
}

resource "aws_lb_target_group" "tg" {
  for_each = var.services

  # TG name 규칙: 32자 제한/허용문자 제한 때문에 정리
  name = substr(
    replace("${var.name}-${each.key}", "_", "-"),
    0,
    32
  )

  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = each.value.container_port
  target_type = "ip"

  health_check {
    path                = each.value.health_check_path
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# path-based rule: "/auth/*" -> auth-service TG
resource "aws_lb_listener_rule" "svc" {
  for_each = var.services

  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + index(keys(var.services), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    path_pattern {
      values = ["${each.value.path_prefix}/*"]
    }
  }
}
