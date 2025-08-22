variable "name" {
  description = "리소스 접두사 (예: dailybriefing-dev)"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "ALB가 놓일 퍼블릭 서브넷들"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "certificate_arn" {
  description = "ACM 인증서 ARN (없으면 null → HTTP만 생성)"
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Target Group 헬스체크 경로"
  type        = string
  default     = "/health"
}


# 키=서비스명, 값={ path, port }
variable "routes" {
  description = "경로 기반 라우팅: 서비스명 → { path, port }"
  type = map(object({
    path = string
    port = number
  }))
}

