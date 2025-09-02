variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "certificate_arn" {
  description = "없으면 HTTP만 사용"
  type        = string
  default     = null
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "routes" {
  description = "서비스명 -> {path, port}"
  type = map(object({
    path = string
    port = number
  }))
}

variable "enable_access_logs" {
  type    = bool
  default = false
}

variable "access_logs_bucket" {
  type    = string
  default = null
}

variable "access_logs_prefix" {
  type    = string
  default = "alb/"
}
