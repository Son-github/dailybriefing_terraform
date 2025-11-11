variable "root_domain" {
  description = "예: dailybriefing.example"
  type        = string
}

variable "cf_domain_name" {
  description = "CloudFront 배포 도메인 (ex: dxxxx.cloudfront.net)"
  type        = string
}

variable "cf_hosted_zone_id" {
  description = "CloudFront Hosted Zone ID (배포 출력값)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS (ex: my-alb-123.ap-northeast-2.elb.amazonaws.com)"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB Hosted Zone ID"
  type        = string
}

variable "create_frontend_cert" {
  description = "CloudFront용(us-east-1) ACM 인증서 생성 여부"
  type        = bool
  default     = true
}

variable "create_api_cert" {
  description = "ALB용(ap-northeast-2) ACM 인증서 생성 여부"
  type        = bool
  default     = true
}

# SAN에 www 붙일지 여부(선택)
variable "include_www" {
  type    = bool
  default = false
}
