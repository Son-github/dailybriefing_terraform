data "aws_region" "current" {}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

# Subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_c_cidr
  availability_zone       = var.az_c
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-c" }
}

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_a_cidr
  availability_zone = var.az_a
  tags = { Name = "${var.name}-private-app-a" }
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_a_cidr
  availability_zone = var.az_a
  tags = { Name = "${var.name}-private-db-a" }
}

resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_c_cidr
  availability_zone = var.az_c
  tags = { Name = "${var.name}-private-db-c" }
}

# NAT (단일) - 비용 절감
resource "aws_eip" "nat" { domain = "vpc"  tags = { Name = "${var.name}-nat-eip" } }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "${var.name}-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0"  gateway_id = aws_internet_gateway.igw.id }
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_c" {
  subnet_id = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0"  nat_gateway_id = aws_nat_gateway.nat.id }
  tags = { Name = "${var.name}-private-rt" }
}

resource "aws_route_table_association" "app_a" {
  subnet_id = aws_subnet.app_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "db_a" {
  subnet_id = aws_subnet.db_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "db_c" {
  subnet_id = aws_subnet.db_c.id
  route_table_id = aws_route_table.private.id
}

# Interface VPC Endpoint용 SG (옵션)
resource "aws_security_group" "vpce" {
  name   = "${var.name}-vpce-sg"
  vpc_id = aws_vpc.this.id

  # VPC 내에서 443 접근 허용
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# (옵션) VPC Interface Endpoints
resource "aws_vpc_endpoint" "ssm" {
  count                = var.enable_vpc_endpoints ? 1 : 0
  vpc_id               = aws_vpc.this.id
  service_name         = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type    = "Interface"
  private_dns_enabled  = true
  subnet_ids           = [aws_subnet.app_a.id]
  security_group_ids   = [aws_security_group.vpce.id]
}

resource "aws_vpc_endpoint" "logs" {
  count                = var.enable_vpc_endpoints ? 1 : 0
  vpc_id               = aws_vpc.this.id
  service_name         = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type    = "Interface"
  private_dns_enabled  = true
  subnet_ids           = [aws_subnet.app_a.id]
  security_group_ids   = [aws_security_group.vpce.id]
}

resource "aws_vpc_endpoint" "ecr_api" {
  count                = var.enable_vpc_endpoints ? 1 : 0
  vpc_id               = aws_vpc.this.id
  service_name         = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type    = "Interface"
  private_dns_enabled  = true
  subnet_ids           = [aws_subnet.app_a.id]
  security_group_ids   = [aws_security_group.vpce.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count                = var.enable_vpc_endpoints ? 1 : 0
  vpc_id               = aws_vpc.this.id
  service_name         = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type    = "Interface"
  private_dns_enabled  = true
  subnet_ids           = [aws_subnet.app_a.id]
  security_group_ids   = [aws_security_group.vpce.id]
}
