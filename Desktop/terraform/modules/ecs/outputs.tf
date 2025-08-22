#############################################
# modules/ecs/outputs.tf  (fixed)
#############################################

output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

# SG는 VPC 모듈에서 주입받으므로, 입력 변수를 그대로 노출
output "ecs_security_group_id" {
  description = "Injected ECS Security Group ID (from VPC module)"
  value       = var.ecs_security_group_id
}

# 참고용: 생성된 서비스 키 목록
output "service_names" {
  description = "Service keys (names) created in this module"
  value       = keys(var.services)
}

# 참고용: 로그 그룹 이름 매핑
output "log_group_names" {
  description = "Service name -> CloudWatch Log Group name"
  value       = { for k, lg in aws_cloudwatch_log_group.svc : k => lg.name }
}

# 선택: 태스크 정의 ARN 매핑(있으면 유용)
output "task_definition_arns" {
  description = "Service name -> Task Definition ARN"
  value       = { for k, td in aws_ecs_task_definition.svc : k => td.arn }
}
