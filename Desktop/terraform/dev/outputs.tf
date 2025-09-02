output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "frontend_cdn_domain" {
  value = module.cloudfront.distribution_domain_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

# 프론트 배포 편의용
output "s3_site_bucket_id" {
  value = module.s3_site.bucket_id
}
output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}
