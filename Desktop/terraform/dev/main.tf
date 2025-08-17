locals {
  tags = {
    Project = var.project
    Env     = var.env
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
  public_subnet_id = module.subnets.public_subnet_ids[0]
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

# 6) ECR (+ GitHub OIDC Role)
module "ecr" {
  source = "../modules/ecr"

  project      = var.project
  repositories = [
    "auth-service",
    "exchange-service",
    "weather-service",
    "news-service",
    "news-sentiment",
    "frontend"
  ]

  # 이미지 정리 정책
  untagged_expire_days = 7
  keep_last_images     = 20
  force_delete         = false

  # GitHub OIDC
  enable_github_oidc = true
  github_org         = "Son-github"
  github_repo        = "dailybriefing"
  allowed_branches   = ["main"]
  github_role_name   = "${var.project}-gha-ecr-push"

  tags = local.tags
}

# 7) (선택) VPC Interface Endpoints — ECR API / DKR
resource "aws_security_group" "vpce_sg" {
  name        = "${var.project}-vpce-sg"
  description = "VPC endpoints SG (443)"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # 운영은 소스 SG로 좁히기 권장
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"   # ← 변경
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.subnets.app_subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "${var.project}-vpce-ecr-api" })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"   # ← 변경
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.subnets.app_subnet_ids
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
  tags                = merge(local.tags, { Name = "${var.project}-vpce-ecr-dkr" })
}

# (선택) S3 Gateway Endpoint — 프라이빗에서 ECR layer 접근 비용 추가 절감
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = module.vpc.vpc_id
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = concat(
#     module.routes.app_route_table_ids,
#     module.routes.db_route_table_ids
#   )
#   tags = merge(local.tags, { Name = "${var.project}-vpce-s3" })
# }
