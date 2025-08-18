variable "name" {}
variable "vpc_cidr" {}
variable "az_a" {}
variable "az_c" {}
variable "public_a_cidr" {}
variable "public_c_cidr" {}
variable "app_a_cidr" {}
variable "db_a_cidr" {}
variable "db_c_cidr" {}
variable "enable_vpc_endpoints" { type = bool, default = false }
