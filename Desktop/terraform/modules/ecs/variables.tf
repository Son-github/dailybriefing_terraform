variable "name" {}
variable "cluster_name" {}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "alb_sg_id" {}
variable "http_listener_arn" {}
variable "https_listener_arn" { default = null }
variable "target_group_vpc_id" {}
variable "db_sg_id" {}

variable "services" {
  type = list(object({
    name           : string
    image          : string
    container_port : number
    path           : string
    desired_count  : number
    cpu            : number
    memory         : number
    health_path    : string
    env            : map(string)
  }))
}

variable "ssm_parameter_paths" {
  description = "ECS가 읽어야할 SSM 파라미터 이름들(정확 경로)"
  type        = list(string)
  default     = []
}
