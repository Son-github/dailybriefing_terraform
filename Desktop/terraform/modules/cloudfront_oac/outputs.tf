output "distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "distribution_hosted_zone_id" {
  value = aws_cloudfront_distribution.cdn.hosted_zone_id
}

output "oac_id" {
  value = aws_cloudfront_origin_access_control.oac.id
}
