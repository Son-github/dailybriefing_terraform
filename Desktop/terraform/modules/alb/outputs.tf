output "alb_arn"           { value = aws_lb.this.arn }
output "alb_dns_name"      { value = aws_lb.this.dns_name }
output "http_listener_arn" { value = aws_lb_listener.http.arn }
output "https_listener_arn" {
  value       = try(aws_lb_listener.https[0].arn, null)
  description = "HTTPS 리스너가 없으면 null"
}
