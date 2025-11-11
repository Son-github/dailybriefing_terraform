data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix    = var.name_prefix
  ecr_repo_prefix = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/dailybriefing"
}

# ---------------- VPC ----------------
module "vpc" {
  source = "../modules/vpc"

  name     = local.name_prefix
  vpc_cidr = "10.2.0.0/16"

  az_a = "ap-northeast-2a"
  az_c = "ap-northeast-2c"

  # Public (ALB)
  public_a_cidr = "10.2.1.0/24"
  public_c_cidr = "10.2.11.0/24"

  # ECS Private (2AZ)
  ecs_a_cidr = "10.2.2.0/24"
  ecs_c_cidr = "10.2.12.0/24"

  # DB Private (2AZ)
  db_a_cidr = "10.2.3.0/24"
  db_c_cidr = "10.2.4.0/24"

  # ✅ B안/프라이빗 Fargate 통신 확보(택1: VPC 엔드포인트 사용)
  enable_vpc_endpoints = true
  # 모듈에서 상세 플래그를 받는다면 아래도 켜줘
  # vpc_endpoints = {
  #   ecr_api = true
  #   ecr_dkr = true
  #   logs    = true
  #   s3      = true
  #   ssm     = true
  # }

  create_sg_bundle  = true
  alb_ingress_cidrs = ["0.0.0.0/0"]

  # ALB → ECS 허용 포트
  ecs_ingress_from_alb_ports = [8081, 8082, 8083, 8084]

  # DB 포트
  db_port = 5432

  # (택2: NAT GW 사용 시—모듈이 지원하면)
  # enable_nat_gateway = true
  # single_nat_gateway = true
}

# ---------------- ALB ----------------
module "alb" {
  source = "../modules/alb"

  name            = local.name_prefix
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  alb_sg_id       = module.vpc.alb_sg_id
  certificate_arn = var.alb_certificate_arn

  enable_access_logs = false
  access_logs_bucket = null
  access_logs_prefix = "alb/"

  routes = {
    auth-service =     { path = "/api/auth/*",     port = 8081 }
    exchange-service = { path = "/api/exchange/*", port = 8082 }
    weather-service =  { path = "/api/weather/*",  port = 8083 }
    news-service =     { path = "/api/news/*",     port = 8084 }
  }
}

# ---------------- ECS ----------------
module "ecs" {
  source = "../modules/ecs"

  name                  = local.name_prefix
  cluster_name          = "${local.name_prefix}-cluster"

  vpc_id                = module.vpc.vpc_id
  ecs_subnet_ids        = module.vpc.ecs_subnet_ids
  ecs_security_group_id = module.vpc.ecs_sg_id
  target_group_arns     = module.alb.target_group_arns

  # (권장) 아래 secrets 주입은 모듈이 지원할 때 사용. 미지원이면 그대로 env 쓰고,
  # 추후 모듈에 secrets(SSM/Secrets Manager) 전달 기능을 추가해.
  services = {
    auth-service = {
      image          = "${local.ecr_repo_prefix}/auth-service:latest"
      container_port = 8081
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env = {
        SPRING_PROFILES_ACTIVE = "dev"
        SERVER_PORT            = "8081"
      }
      # secrets = [
      #   { name = "SPRING_DATASOURCE_URL",      valueFrom = aws_ssm_parameter.db_url.arn },
      #   { name = "SPRING_DATASOURCE_USERNAME", valueFrom = aws_ssm_parameter.db_user.arn },
      #   { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = aws_ssm_parameter.db_pass.arn },
      # ]
    }

    exchange-service = {
      image          = "${local.ecr_repo_prefix}/exchange-service:latest"
      container_port = 8082
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env = {
        SPRING_PROFILES_ACTIVE = "dev"
        SERVER_PORT            = "8082"
      }
      # secrets = [ ... (동일) ]
    }

    weather-service = {
      image          = "${local.ecr_repo_prefix}/weather-service:latest"
      container_port = 8083
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env = {
        SPRING_PROFILES_ACTIVE = "dev"
        SERVER_PORT            = "8083"
      }
      # secrets = [ ... ]
    }

    news-service = {
      image          = "${local.ecr_repo_prefix}/news-service:latest"
      container_port = 8084
      desired_count  = 1
      cpu            = 256
      memory         = 512
      env = {
        SPRING_PROFILES_ACTIVE = "dev"
        SERVER_PORT            = "8084"
      }
      # secrets = [ ... ]
    }
  }

  enable_autoscaling = false
  autoscaling = {
    min_capacity = 1
    max_capacity = 2
    target_cpu   = 60
  }

  depends_on = [module.alb]
}

# ---------------- RDS(Postgres) ----------------
module "rds" {
  source = "../modules/rds"

  name          = local.name_prefix
  db_subnet_ids = module.vpc.db_subnet_ids
  rds_sg_id     = module.vpc.db_sg_id

  db_name     = "dashboard"
  db_username = "appuser"
  db_password = "11111111"   # ✅ 추후 SSM/Secrets로 이동 권장

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

# ---------------- Frontend (S3 + CloudFront OAC) ----------------
module "s3_site" {
  source               = "../modules/s3_site"
  name                 = local.name_prefix
  bucket_force_destroy = true
  enable_versioning    = false
}

module "cloudfront" {
  source                = "../modules/cloudfront_oac"
  name                  = local.name_prefix

  # S3
  s3_bucket_id          = module.s3_site.bucket_id
  s3_bucket_arn         = module.s3_site.bucket_arn
  s3_bucket_domain_name = module.s3_site.bucket_regional_domain_name

  # CF 인증서(us-east-1)
  certificate_arn       = var.frontend_certificate_arn
  default_root_object   = "index.html"
  price_class           = "PriceClass_200"

  # ✅ B안: CloudFront가 API를 프록시하지 않음
  enable_api_origin = false

  # (권장) SPA 라우팅: 403/404 → /index.html로 리다이렉트 옵션이 모듈에 있다면 켜줘
  # spa_redirect_403_to_index = true
  # spa_redirect_404_to_index = true
}
