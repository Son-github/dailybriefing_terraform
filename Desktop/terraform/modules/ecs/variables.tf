variable "name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "db_sg_id" {
  type    = string
  default = ""
}

variable "cpu_architecture" {
  type    = string
  default = "X86_64"
}

variable "cloudwatch_retention_days" {
  type    = number
  default = 14
}

variable "services" {
  type = map(object({
    image          = string
    container_port = number
    desired_count  = number
    cpu            = number
    memory         = number
    env            = map(string)
  }))
}

variable "target_group_arns" {
  description = "서비스명 -> TG ARN (있으면 ALB 연결)"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  type    = bool
  default = false
}

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
