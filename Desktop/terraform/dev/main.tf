locals {
  tags = {
    Project = var.project
    Env     = "dev"
  }

  public_names = ["${var.project}-public-a", "${var.project}-public-c"]
  public_cidrs = [var.public_a_cidr, var.public_c_cidr]
  public_azs   = [var.az_a, var.az_c]

  app_names = ["${var.project}-private-app-a"]
  app_cidrs = [var.app_a_cidr]
  app_azs   = [var.az_a]

  db_names = ["${var.project}-private-db-a", "${var.project}-private-db-c"]
  db_cidrs = [var.db_a_cidr, var.db_c_cidr]
  db_azs   = [var.az_a, var.az_c]
}

# 1) VPC + IGW
module "vpc" {
  source   = "../modules/vpc"
  name     = var.project
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

# 2) Subnets
module "subnets" {
  source = "../modules/subnets"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags

  public_names = local.public_names
  public_cidrs = local.public_cidrs
  public_azs   = local.public_azs

  app_names = local.app_names
  app_cidrs = local.app_cidrs
  app_azs   = local.app_azs

  db_names = local.db_names
  db_cidrs = local.db_cidrs
  db_azs   = local.db_azs
}

# 3) NAT (Public A에 1개)
module "nat" {
  source           = "../modules/nat"
  name             = var.project
  public_subnet_id = module.subnets.public_subnet_ids[0] # public-a
  tags             = local.tags
}

# 4) Routes
module "routes" {
  source            = "../modules/routes"
  name              = var.project
  vpc_id            = module.vpc.vpc_id
  igw_id            = module.vpc.igw_id
  nat_gateway_id    = module.nat.nat_gateway_id
  public_subnet_ids = module.subnets.public_subnet_ids
  app_subnet_ids    = module.subnets.app_subnet_ids
  db_subnet_ids     = module.subnets.db_subnet_ids
  tags              = local.tags
}

# 5) RDS Subnet Group (DB A/C)
module "rds_subnet_group" {
  source        = "../modules/rds_subnet_group"
  name          = var.project
  db_subnet_ids = module.subnets.db_subnet_ids
  tags          = local.tags
}

output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnets" { value = module.subnets.public_subnet_ids }
output "private_app_subnets" { value = module.subnets.app_subnet_ids }
output "private_db_subnets" { value = module.subnets.db_subnet_ids }
output "rds_subnet_group_id" { value = module.rds_subnet_group.id }
