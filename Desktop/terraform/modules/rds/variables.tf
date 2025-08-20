variable "name"                 {
  type = string
}

variable "private_subnet_db_ids"{
  type = list(string)
}

variable "rds_sg_id"            {
  type = string
}

variable "engine"         {
  type = string
  default = "postgres"
}

variable "engine_version" {
  type = string
  default = "15.5"
}

variable "db_name"        {
  type = string
  default = "dashboard"
}

# ★ 요청대로 고정
variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  default   = "11111111"
  sensitive = true
}

# ★ 자동 생성/관리 비활성화(항상 우리가 준 비번 사용)
variable "manage_master_user_password" {
  type    = bool
  default = false
}

variable "instance_class"        {
  type = string
  default = "db.t4g.micro"
}

variable "allocated_storage"     {
  type = number
  default = 20
}

variable "storage_encrypted"     {
  type = bool
  default = true
}

variable "backup_retention_period"{
  type = number
  default = 7
}

variable "deletion_protection"   {
  type = bool
  default = false
}

variable "apply_immediately"     {
  type = bool
  default = true
}

variable "publicly_accessible"   {
  type = bool
  default = false
}

variable "multi_az"              {
  type = bool
  default = false
}

variable "skip_final_snapshot"   {
  type = bool
  default = true
}


