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
