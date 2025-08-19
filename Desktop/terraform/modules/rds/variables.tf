variable "name"          { type = string }
variable "vpc_id"        { type = string }
variable "db_subnet_ids" { type = list(string) }
variable "username"      { type = string }

variable "password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "dashboard"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = "15.5"
}
