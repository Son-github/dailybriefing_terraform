variable "name" { type = string }
variable "cluster_name" { type = string }

variable "vpc_id" { type = string }
variable "ecs_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }

# alb 모듈 output(map)
variable "target_group_arns" { type = map(string) }

variable "services" {
  type = map(object({
    image          = string
    container_port = number
    desired_count  = number
    cpu            = number
    memory         = number
    env            = optional(map(string), {})
  }))
}

variable "common_env" { type = map(string), default = {} }

variable "enable_autoscaling" { type = bool, default = false }
variable "autoscaling" {
  type = object({
    min_capacity = number
    max_capacity = number
    target_cpu   = number
  })
  default = {
    min_capacity = 1
    max_capacity = 2
    target_cpu   = 60
  }
}
