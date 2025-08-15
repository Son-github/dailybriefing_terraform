variable "project" { default = "dailybriefing" }
variable "vpc_cidr" { default = "10.0.0.0/16" }

variable "az_a" { default = "ap-northeast-2a" }
variable "az_c" { default = "ap-northeast-2c" }

variable "public_a_cidr" { default = "10.0.1.0/24" }
variable "public_c_cidr" { default = "10.0.3.0/24" }
variable "app_a_cidr" { default = "10.0.2.0/24" }
variable "db_a_cidr" { default = "10.0.10.0/24" }
variable "db_c_cidr" { default = "10.0.12.0/24" }
