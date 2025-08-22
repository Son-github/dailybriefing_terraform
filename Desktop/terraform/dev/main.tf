locals {
  name_prefix = "dailybriefing-dev"
}

# VPC (이미 적용해둔 모듈)
module "vpc" {
  source = "../modules/vpc"

  name       = local.name_prefix

  vpc_cidr = "10.2.0.0/16"
  az_a     = "ap-northeast-2a"
  az_c     = "ap-northeast-2c"

  # 퍼블릭 2개 (서로 다른 AZ, 겹치지 않는 CIDR)
  public_a_cidr = "10.2.1.0/24"
  public_c_cidr = "10.2.11.0/24" # ← 충돌 안 나는 새 대역으로 변경

  # 프라이빗
  ecs_cidr  = "10.2.2.0/24"
  db_a_cidr = "10.2.3.0/24"
  db_c_cidr = "10.2.4.0/24"

  enable_vpc_endpoints       = false
  create_sg_bundle           = true
  alb_ingress_cidrs          = ["0.0.0.0/0"]
  ecs_ingress_from_alb_ports = [8082, 8083, 8084]
  db_port                    = 5432

}

module "rds" {
  source = "../modules/rds"

  name          = "dailybriefing-dev"
  db_subnet_ids = module.vpc.db_subnet_ids # ✅ VPC 출력과 이름 일치
  rds_sg_id     = module.vpc.db_sg_id

  db_name     = "dashboard"
  db_username = "appuser"
  db_password = "11111111"

  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  storage_encrypted       = true
  backup_retention_period = 7
  deletion_protection     = false
  apply_immediately       = true
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

# ECS (Fargate, 프라이빗 서브넷에서 기동 모든 서비스 → DB 허용)
module "ecs" {
  source                = "../modules/ecs"
  name                  = local.name_prefix
  cluster_name          = "${local.name_prefix}-cluster"
  vpc_id                = module.vpc.vpc_id
  ecs_subnet_ids        = [module.vpc.ecs_subnet_id]
  ecs_security_group_id = module.vpc.ecs_sg_id

  # ALB TargetGroup 매핑 (키는 services와 동일)
  target_group_arns = module.alb.target_group_arns

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

  # 🔑 ALB 모듈이 끝난 뒤에 ECS 생성
  depends_on = [module.alb]
}

module "alb" {
  source          = "../modules/alb"
  name            = local.name_prefix
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids # ✅ 두 AZ 서브넷 전달
  alb_sg_id       = module.vpc.alb_sg_id
  certificate_arn = var.alb_certificate_arn

  routes = {
    exchange-service = { path = "/exchange/*", port = 8082 }
    weather-service  = { path = "/weather/*", port = 8083 }
    news-service     = { path = "/news/*", port = 8084 }
  }
}

# 1) S3 정적 버킷
module "s3_site" {
  source              = "../modules/s3_site"
  name                = local.name_prefix
  bucket_force_destroy = true
  tags = {
    Project = "dailybriefing"
    Env     = "dev"
  }
}

# 2) CloudFront + OAC (버킷 정책까지)
module "cloudfront" {
  source                  = "../modules/cloudfront_oac"
  name                    = local.name_prefix
  s3_bucket_id            = module.s3_site.bucket_id
  s3_bucket_arn           = module.s3_site.bucket_arn
  s3_bucket_domain_name   = module.s3_site.bucket_regional_domain_name  # ✅ 추가

  certificate_arn         = var.frontend_certificate_arn  # 없으면 기본 인증서
  default_root_object     = "index.html"
  price_class             = "PriceClass_200"
  tags = {
    Project = "dailybriefing"
    Env     = "dev"
  }
}
