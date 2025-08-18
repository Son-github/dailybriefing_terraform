variable "project" { type = string, default = "dailybriefing" }
variable "env"     { type = string, default = "dev" }
variable "region"  { type = string, default = "ap-northeast-2" }

variable "vpc_cidr"      { type = string, default = "10.0.0.0/16" }
variable "az_a"          { type = string, default = "ap-northeast-2a" }
variable "az_c"          { type = string, default = "ap-northeast-2c" }
variable "public_a_cidr" { type = string, default = "10.0.1.0/24" }
variable "public_c_cidr" { type = string, default = "10.0.3.0/24" }
variable "app_a_cidr"    { type = string, default = "10.0.2.0/24" }
variable "db_a_cidr"     { type = string, default = "10.0.10.0/24" }
variable "db_c_cidr"     { type = string, default = "10.0.12.0/24" }

variable "enable_vpc_endpoints" {
  description = "SSM/Logs/ECR 인터페이스 엔드포인트 생성(옵션, NAT 비용 절감)"
  type        = bool
  default     = false
}

# ALB (옵션) HTTPS
variable "alb_certificate_arn" {
  description = "ap-northeast-2의 ACM 인증서 ARN. 비우면 HTTP만."
  type        = string
  default     = ""
}

# CloudFront / S3 (옵션) 커스텀 도메인
variable "frontend_domain_name" {
  description = "CloudFront 커스텀 도메인 (Route53+ACM(us-east-1) 필요)."
  type        = string
  default     = ""
}
variable "cloudfront_certificate_arn" {
  description = "us-east-1 ACM 인증서 ARN (커스텀 도메인 사용 시 필수)."
  type        = string
  default     = ""
}

# ECS 서비스 정의
variable "ecs_services" {
  description = "Path 기반 라우팅 대상 ECS 서비스 목록"
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
  default = [
    {
      name           = "exchange-service"
      image          = "public.ecr.aws/amazonlinux/amazonlinux:latest"
      container_port = 8080
      path           = "/exchange*"
      desired_count  = 1
      cpu            = 256
      memory         = 512
      health_path    = "/actuator/health"
      env            = {}
    },
    {
      name           = "weather-service"
      image          = "public.ecr.aws/amazonlinux/amazonlinux:latest"
      container_port = 8080
      path           = "/weather*"
      desired_count  = 1
      cpu            = 256
      memory         = 512
      health_path    = "/actuator/health"
      env            = {}
    },
    {
      name           = "news-service"
      image          = "public.ecr.aws/amazonlinux/amazonlinux:latest"
      container_port = 8080
      path           = "/news*"
      desired_count  = 1
      cpu            = 256
      memory         = 512
      health_path    = "/actuator/health"
      env            = {}
    }
  ]
}

# RDS (PostgreSQL)
variable "db_username"         { type = string }
variable "db_password"         { type = string, sensitive = true }
variable "db_name"             { type = string, default = "dashboard" }
variable "db_instance_class"   { type = string, default = "db.t4g.micro" }
variable "db_allocated_storage"{ type = number, default = 20 }
variable "db_engine_version"   { type = string, default = "15.5" }

# SSM 파라미터 (API Key 등)
variable "ssm_parameters" {
  description = "SSM Parameter Store (SecureString) name → value"
  type        = map(string)
  default     = {}
}
