variable "name"     { type = string }
variable "vpc_cidr" { type = string }

# AZ 두 개: ECS는 a에만, DB는 a,c에 배치
variable "az_a" { type = string }
variable "az_c" { type = string }

# 서브넷 CIDR
variable "public_cidr" { type = string } # AZ-a
variable "ecs_cidr"    { type = string } # AZ-a (ECS)
variable "db_a_cidr"   { type = string } # AZ-a (DB)
variable "db_c_cidr"   { type = string } # AZ-c (DB)

# VPC Endpoint 토글
variable "enable_vpc_endpoints" {
  type    = bool
  default = false
}

# ... (기존 변수들 위/아래 유지)

# SG 번들 생성 토글
variable "create_sg_bundle" {
  type    = bool
  default = true
}

# ALB 인바운드 허용 CIDR (기본: 전체)
variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# ALB → ECS로 열어줄 애플리케이션 포트 목록 (비우면 규칙 생성 안 함)
variable "ecs_ingress_from_alb_ports" {
  type    = list(number)
  default = []
}

# DB 포트 (PostgreSQL=5432, MySQL=3306 등)
variable "db_port" {
  type    = number
  default = 5432
}

