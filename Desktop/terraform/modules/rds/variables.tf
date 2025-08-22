variable "name" {
  type = string
}

variable "rds_sg_id" {
  description = "DB Security Group ID"
  type        = string
}

# 선호: 새 이름
variable "db_subnet_ids" {
  description = "RDS가 사용할 DB 서브넷 ID 목록 (2개 이상 권장)"
  type        = list(string)
  default     = []
}

# 과거 호환: 예전 이름
variable "private_subnet_db_ids" {
  description = "(레거시) db_subnet_ids의 과거 변수명"
  type        = list(string)
  default     = []
}

# 나머지 파라미터들…
variable "engine" {
  type    = string
  default = "postgres"
}

# engine_version는 생략 권장(리전 최신 자동)
# variable "engine_version" { type = string }

variable "db_name" {
  type    = string
  default = "dashboard"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type = string
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "apply_immediately" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}
