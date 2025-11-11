output "frontend_certificate_arn" {
  value = try(aws_acm_certificate_validation.frontend[0].certificate_arn, null)
}

output "api_certificate_arn" {
  value = try(aws_acm_certificate_validation.api[0].certificate_arn, null)
}

output "root_record_name" {
  value = aws_route53_record.root_a.name
}

output "api_record_name" {
  value = aws_route53_record.api_a.name
}

