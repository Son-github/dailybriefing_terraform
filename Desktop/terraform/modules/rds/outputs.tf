output "db_endpoint" {
  description = "RDS 접속 엔드포인트"
  value       = aws_db_instance.rds.address
}

output "master_user_secret_arn" {
  description = "자동 생성된 마스터 암호 Secret ARN (manage_master_user_password=true일 때)"
  value       = try(aws_db_instance.rds.master_user_secret[0].secret_arn, null)
}
