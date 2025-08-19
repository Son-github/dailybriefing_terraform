variable "name"         { type = string }
variable "cluster_name" { type = string }
variable "vpc_id"       { type = string }

# 단일 AZ이지만, 인터페이스 통일성을 위해 list(string)
variable "ecs_subnet_ids" { type = list(string) }

# RDS 모듈에서 나온 DB SG (5432 인바운드 허용 대상)
variable "db_sg_id" { type = string }

variable "services" {
  type = list(object({
    name           = string
    image          = string
    container_port = number
    desired_count  = number
    cpu            = number
    memory         = number
    env            = map(string)
    health_path    = optional(string)
  }))
}
