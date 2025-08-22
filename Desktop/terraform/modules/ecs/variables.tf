variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ecs_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

# DB SG가 준비되기 전에도 모듈이 돌아가도록 기본값은 빈 문자열
variable "db_sg_id" {
  description = "RDS/PostgreSQL security group ID (5432 will be opened from ECS SG). Leave empty to skip."
  type        = string
  default     = ""
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention (days)"
  type        = number
  default     = 14
}

variable "cpu_architecture" {
  description = "Task CPU architecture (X86_64 or ARM64)"
  type        = string
  default     = "X86_64"
}

# ★ 에러 최소화를 위해 map(object) 사용. 키가 서비스명
variable "services" {
  description = "Fargate services keyed by service name"
  type = map(object({
    image          = string
    container_port = number
    desired_count  = number
    cpu            = number
    memory         = number
    env            = map(string)
  }))
}

# ALB의 TG를 주입받아 ECS 서비스와 연결 (선택)
variable "target_group_arns" {
  description = "서비스명 → Target Group ARN 매핑 (있으면 ALB에 연결)"
  type        = map(string)
  default     = {}
}

variable "ecs_security_group_id" {
  description = "VPC 모듈이 생성한 ECS SG ID"
  type        = string
}

