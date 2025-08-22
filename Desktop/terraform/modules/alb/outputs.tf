output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.this.dns_name
}

output "https_listener_arn" {
  description = "HTTPS 리스너 ARN (없으면 null)"
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "target_group_arns" {
  description = "서비스명 → Target Group ARN 매핑"
  value       = { for k, tg in aws_lb_target_group.svc : k => tg.arn }
}
