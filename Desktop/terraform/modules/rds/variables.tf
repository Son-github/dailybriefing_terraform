variable "name" {}
variable "vpc_id" {}
variable "db_subnet_ids" { type = list(string) }
variable "db_sg_id" {}
variable "username" {}
variable "password" { sensitive = true }
variable "db_name" { default = "dashboard" }
variable "instance_class" { default = "db.t4g.micro" }
variable "allocated_storage" { default = 20 }
variable "engine_version" { default = "15.5" }
