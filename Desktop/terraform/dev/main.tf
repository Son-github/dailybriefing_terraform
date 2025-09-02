locals {
  name_prefix = var.name_prefix
}

# ---------------- VPC ----------------
module "vpc" {
  source = "../modules/vpc"

  name     = local.name_prefix
  vpc_cidr = "10.2.0.0/16"

  az_a = "ap-northeast-2a"
  az_c = "ap-northeast-2c"

  public_a_cidr = "10.2.1.0/24"
  public_c_cidr = "10.2.11.0/24"

  ecs_cidr  = "10.2.2.0/24"
  db_a_cidr = "10.2.3.0/24"
  db_c_cidr = "10.2.4.0/24"

  enable_vpc_endpoints       = false
  create_sg_bundle           = true
  alb_ingress_cidrs          = ["0.0.0.0/0"]
  ecs_ingress_from_alb_ports = [8082, 8083, 8084]
  db_port                    = 5432
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
    exchange-service = { path = "/exchange/*", port = 8082 }
    weather-service  = { path = "/weather/*",  port = 8083 }
    news-service     = { path = "/news/*",     port = 8084 }
  }
}

# ---------------- ECS ----------------
module "ecs" {
  source = "../modules/ecs"

  name                  = local.name_prefix
  cluster_name          = "${local.name_prefix}-cluster"
  vpc_id                = module.vpc.vpc_id
  ecs_subnet_ids        = [module.vpc.ecs_subnet_id]
  ecs_security_group_id = module.vpc.ecs_sg_id
  db_sg_id              = module.vpc.db_sg_id

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
  db_password = "11111111"   # dev only

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

# ---------------- Frontend ----------------
module "s3_site" {
  source               = "../modules/s3_site"
  name                 = local.name_prefix
  bucket_force_destroy = true
  enable_versioning    = false
}

module "cloudfront" {
  source                = "../modules/cloudfront_oac"
  name                  = local.name_prefix
  s3_bucket_id          = module.s3_site.bucket_id
  s3_bucket_arn         = module.s3_site.bucket_arn
  s3_bucket_domain_name = module.s3_site.bucket_regional_domain_name
  certificate_arn       = var.frontend_certificate_arn
  default_root_object   = "index.html"
  price_class           = "PriceClass_200"
}
