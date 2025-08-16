# 프로젝트/환경
variable "project" {
  type    = string
  default = "dailybriefing"
}

variable "env" {
  type    = string
  default = "dev"
}

# 리전/프로필
variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "aws_profile" {
  type    = string
  default = "dailybriefing"
}

# AZ
variable "az_a" {
  type    = string
  default = "ap-northeast-2a"
}

variable "az_c" {
  type    = string
  default = "ap-northeast-2c"
}

# VPC/CIDR
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_a_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_c_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "app_a_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "db_a_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "db_c_cidr" {
  type    = string
  default = "10.0.12.0/24"
}
