variable "region" {
  description = "AWS region for this dev stack"
  type        = string
  default     = "ap-northeast-2"
}

# RDS(PostgreSQL)
variable "db_username"         { type = string }
variable "db_password"         { type = string, sensitive = true }
variable "db_name"             { type = string, default = "dashboard" }
variable "db_instance_class"   { type = string, default = "db.t4g.micro" }
variable "db_allocated_storage"{ type = number, default = 20 }
variable "db_engine_version"   { type = string, default = "15.5" }

# ECS Services (ALB 없이 프라이빗에서 기동)
variable "ecs_services" {
  description = "Fargate services to run in the private ECS subnet"
  type = list(object({
    name           = string
    image          = string
    container_port = number
    desired_count  = number
    cpu            = number
    memory         = number
    env            = map(string)         # 예: DB_URL, API_KEYS 등
    health_path    = optional(string)    # (미사용: ALB 없으므로 선택)
  }))
  default = [
    # 예시들 (ECR URI로 교체)
    {
      name           = "auth-service"
      image          = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/auth-service:latest"
      container_port = 8081
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env            = {}
    },
    {
      name           = "exchange-service"
      image          = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/exchange-service:latest"
      container_port = 8082
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env            = {}
    },
    {
      name           = "weather-service"
      image          = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/weather-service:latest"
      container_port = 8083
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env            = {}
    },
    {
      name           = "news-service"
      image          = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/news-service:latest"
      container_port = 8084
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env            = {}
    }
  ]
}

