output "repository_urls" {
  description = "리포지토리 이름 => URL (map)"
  value = {
    for k, v in aws_ecr_repository.this :
    k => v.repository_url
  }
}

output "repository_arns" {
  description = "리포지토리 이름 => ARN (map)"
  value = {
    for k, v in aws_ecr_repository.this :
    k => v.arn
  }
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC Role ARN (생성 시)"
  value       = try(aws_iam_role.gha_ecr_push[0].arn, null)
}
