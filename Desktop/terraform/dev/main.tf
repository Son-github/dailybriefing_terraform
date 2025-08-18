locals { name_prefix = "${var.project}-${var.env}" }

module "vpc" {
  source           = "./modules/vpc"
  name             = local.name_prefix
  vpc_cidr         = var.vpc_cidr
  az_a             = var.az_a
  az_c             = var.az_c
  public_a_cidr    = var.public_a_cidr
  public_c_cidr    = var.public_c_cidr
  app_a_cidr       = var.app_a_cidr
  db_a_cidr        = var.db_a_cidr
  db_c_cidr        = var.db_c_cidr
  enable_vpc_endpoints = var.enable_vpc_endpoints
}

module "security" {
  source = "./modules/security"
  name   = local.name_prefix
  vpc_id = module.vpc.vpc_id

  alb_sg_ingress_cidrs = ["0.0.0.0/0"]
}

module "alb" {
  source         = "./modules/alb"
  name           = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
  alb_sg_id      = module.security.alb_sg_id
  certificate_arn = var.alb_certificate_arn
}

module "ecs_services" {
  source             = "./modules/ecs_service"
  name               = local.name_prefix
  cluster_name       = "${local.name_prefix}-cluster"
  vpc_id             = module.vpc.vpc_id
  private_subnets    = [module.vpc.app_subnet_id]
  alb_sg_id          = module.security.alb_sg_id
  http_listener_arn  = module.alb.http_listener_arn
  https_listener_arn = module.alb.https_listener_arn
  target_group_vpc_id = module.vpc.vpc_id
  services           = var.ecs_services
  db_sg_id           = module.security.db_sg_id
  ssm_parameter_paths = keys(var.ssm_parameters)
}

module "rds" {
  source            = "./modules/rds"
  name              = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  db_subnet_ids     = module.vpc.db_subnet_ids
  db_sg_id          = module.security.db_sg_id
  username          = var.db_username
  password          = var.db_password
  db_name           = var.db_name
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  engine_version    = var.db_engine_version
}

module "s3_cloudfront" {
  source = "./modules/s3_cloudfront"
  providers = { aws.us_east_1 = aws.us_east_1 }
  name                       = local.name_prefix
  domain_name                = var.frontend_domain_name
  cloudfront_certificate_arn = var.cloudfront_certificate_arn
}

module "cognito" {
  source = "./modules/cognito"
  name   = local.name_prefix
}

module "ssm_params" {
  source     = "./modules/ssm_params"
  parameters = var.ssm_parameters
}
