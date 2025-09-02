output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "https_listener_arn" {
  value = try(aws_lb_listener.https[0].arn, null)
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.svc : k => tg.arn }
}
