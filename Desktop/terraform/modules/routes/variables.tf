variable "name"   { type = string }
variable "vpc_id" { type = string }

variable "igw_id"         { type = string }
variable "nat_gateway_id" { type = string }

variable "public_subnet_ids" { type = list(string) }
variable "app_subnet_ids"    { type = list(string) }
variable "db_subnet_ids"     { type = list(string) }

variable "tags" {
  type    = map(string)
  default = {}
}
