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

  enable_vpc_endpoints = false
}

# RDS (PostgreSQL, 싱글AZ)
module "rds" {
  source            = "../modules/rds"
  name              = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  db_subnet_ids     = module.vpc.db_subnet_ids
  username          = var.db_username
  password          = var.db_password
  db_name           = var.db_name
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  engine_version    = var.db_engine_version
}

# ECS (Fargate, 프라이빗 서브넷에서 기동, 모든 서비스 → DB 허용)
module "ecs" {
  source         = "../modules/ecs"
  name           = local.name_prefix
  cluster_name   = "${local.name_prefix}-cluster"
  vpc_id         = module.vpc.vpc_id
  ecs_subnet_ids = [module.vpc.ecs_subnet_id] # 단일 AZ
  db_sg_id       = module.rds.db_sg_id
  services       = var.ecs_services
}

# Outputs
output "rds_endpoint" { value = module.rds.db_endpoint }
output "db_sg_id" { value = module.rds.db_sg_id }
output "ecs_cluster" { value = module.ecs.cluster_name }
output "ecs_service_sg" { value = module.ecs.ecs_service_sg_id }
