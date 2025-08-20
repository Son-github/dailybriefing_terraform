locals {
  name_prefix = "dailybriefing-dev"
}

# VPC (이미 적용해둔 모듈)
module "vpc" {
  source = "../modules/vpc"

  name     = local.name_prefix
  vpc_cidr = "10.2.0.0/16"

  az_a = "ap-northeast-2a"
  az_c = "ap-northeast-2c"

  public_cidr = "10.2.1.0/24"
  ecs_cidr    = "10.2.2.0/24"
  db_a_cidr   = "10.2.10.0/24"
  db_c_cidr   = "10.2.12.0/24"

  enable_vpc_endpoints       = false
  create_sg_bundle           = true
  alb_ingress_cidrs          = ["0.0.0.0/0"]            # 필요시 회사 CIDR로 제한
  ecs_ingress_from_alb_ports = [8081, 8082, 8083, 8084] # 서비스 포트 목록
  db_port                    = 5432
}

# 2️⃣ RDS(PostgreSQL) 인스턴스 생성
module "rds" {
  source = "../modules/rds"

  name                  = "dailybriefing-dev"
  private_subnet_db_ids = module.vpc.db_subnet_ids
  rds_sg_id             = module.vpc.db_sg_id

  # 아래 값들은 모듈 기본값(엔진/버전/username/password)으로 충분하니 생략 가능
  # db_username = "admin"
  # db_password = "11111111"
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

# ECS (Fargate, 프라이빗 서브넷에서 기동 모든 서비스 → DB 허용)
module "ecs" {
  source         = "../modules/ecs"
  name           = local.name_prefix
  cluster_name   = "${local.name_prefix}-cluster"
  vpc_id         = module.vpc.vpc_id
  ecs_subnet_ids = [module.vpc.ecs_subnet_id]

  # RDS 모듈 붙여놨으면 db_sg_id 전달, 아니면 생략 가능(빈 기본값)
  # db_sg_id = try(module.rds.db_sg_id, "")

  services = {
    exchange-service = {
      image          = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/exchange-service:latest"
      container_port = 8082
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env            = { SPRING_PROFILES_ACTIVE = "dev" }
    }
    weather-service = {
      image          = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/weather-service:latest"
      container_port = 8083
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env            = { SPRING_PROFILES_ACTIVE = "dev" }
    }
    news-service = {
      image          = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/news-service:latest"
      container_port = 8084
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env            = { SPRING_PROFILES_ACTIVE = "dev" }
    }
  }
}

