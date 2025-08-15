variable "vpc_id" { type = string }

variable "public_names" { type = list(string) }
variable "public_cidrs" { type = list(string) }
variable "public_azs"   { type = list(string) }

variable "app_names" { type = list(string) }
variable "app_cidrs" { type = list(string) }
variable "app_azs"   { type = list(string) }

variable "db_names" { type = list(string) }
variable "db_cidrs" { type = list(string) }
variable "db_azs"   { type = list(string) }

variable "tags" {
  type    = map(string)
  default = {}
}
