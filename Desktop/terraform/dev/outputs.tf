# 네트워크
output "vpc_id" {
  value = module.vpc.vpc_id
}
output "public_subnets" {
  value = module.subnets.public_subnet_ids
}
output "private_app_subnets" {
  value = module.subnets.app_subnet_ids
}
output "private_db_subnets" {
  value = module.subnets.db_subnet_ids
}
output "rds_subnet_group_id" {
  value = module.rds_subnet_group.id
}

# VPC Endpoints
output "vpce_ecr_api_id" {
  value = aws_vpc_endpoint.ecr_api.id
}
output "vpce_ecr_dkr_id" {
  value = aws_vpc_endpoint.ecr_dkr.id
}

# ECR
output "ecr_repository_urls" {
  value       = module.ecr.repository_urls
  description = "리포지토리 이름 => URL"
}
output "ecr_repository_arns" {
  value       = module.ecr.repository_arns
  description = "리포지토리 이름 => ARN"
}
output "github_actions_role_arn" {
  value       = module.ecr.github_actions_role_arn
  description = "GitHub Actions OIDC Role ARN"
}
