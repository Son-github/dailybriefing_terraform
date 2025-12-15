variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }

variable "services" {
  type = map(object({
    container_port    = number
    path_prefix       = string
    health_check_path = optional(string, "/actuator/health")
  }))
}
