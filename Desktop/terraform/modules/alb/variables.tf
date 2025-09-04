variable "name" {
  type        = string
  description = "Name prefix for ALB resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB/TGs"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for ALB (public)"
}

variable "alb_sg_id" {
  type        = string
  description = "Security group ID for ALB"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS listener (leave null to disable HTTPS)"
  default     = null
}

variable "enable_access_logs" {
  type        = bool
  description = "Enable ALB access logs"
  default     = false
}

variable "access_logs_bucket" {
  type        = string
  description = "S3 bucket for ALB access logs"
  default     = null
}

variable "access_logs_prefix" {
  type        = string
  description = "Prefix for ALB access logs"
  default     = null
}

# 라우트 정의: path, port, (옵션) health_check_path
variable "routes" {
  description = <<EOT
Map of service routes:
{
  service_name = {
    path               = "/api/service/*"
    port               = 8081
    health_check_path  = "/actuator/health" # optional
  }
}
EOT
  type = map(object({
    path              = string
    port              = number
    health_check_path = optional(string)
  }))
}

# 공통 헬스체크 경로(서비스별로 없을 때 fallback)
variable "health_check_path" {
  type        = string
  description = "Default health check path for target groups"
  default     = "/"
}
