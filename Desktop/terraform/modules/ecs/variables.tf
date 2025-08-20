variable "name"         { type = string }                 # 접두사
variable "cluster_name" { type = string }
variable "vpc_id"       { type = string }
variable "ecs_subnet_ids" { type = list(string) }         # 프라이빗 서브넷 IDs
variable "cloudwatch_retention_days" { type = number, default = 14 }

# RDS(Postgres) SG에 5432 인바운드 허용: 빈 문자열이면 생략
variable "db_sg_id" { type = string, default = "" }

# 서비스 스펙
variable "services" {
  description = "Fargate services keyed by service name"
  type = map(object({
    image          = string
    container_port = number
    desired_count  = number
    cpu            = number
    memory         = number
    env            = map(string)
    path           = string   # ALB 안 쓰면 ""로 전달
  }))
}

# --- (옵션) ALB 연동 ---
variable "enable_alb" { type = bool, default = false }
variable "alb_listener_arn" { type = string, default = "" } # HTTPS or HTTP
variable "alb_sg_id"       { type = string, default = "" }  # ALB SG에서만 인바운드 허용
