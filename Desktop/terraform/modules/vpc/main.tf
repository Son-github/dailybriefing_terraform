data "aws_region" "current" {}

# ---------------- VPC ----------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

# ---------------- Subnets ----------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-a", Tier = "public" }
}

resource "aws_subnet" "ecs_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.ecs_cidr
  availability_zone = var.az_a
  tags = { Name = "${var.name}-private-ecs-a", Tier = "private-ecs" }
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_a_cidr
  availability_zone = var.az_a
  tags = { Name = "${var.name}-private-db-a", Tier = "private-db" }
}

resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_c_cidr
  availability_zone = var.az_c
  tags = { Name = "${var.name}-private-db-c", Tier = "private-db" }
}

# ---------------- IGW & Public Route ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# ---------------- NAT (Public Subnet에 배치) ----------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.public_a.id   # ←★ 퍼블릭 서브넷에 반드시 배치
  connectivity_type = "public"
  tags              = { Name = "${var.name}-nat" }
  depends_on        = [aws_internet_gateway.igw]
}

# ---------------- Private Route (ECS만 인터넷 아웃바운드) ----------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  # ECS는 오픈API 호출 등 외부 통신 필요 → NAT 경유
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "${var.name}-private-ecs-rt" }
}

resource "aws_route_table_association" "ecs_a" {
  subnet_id      = aws_subnet.ecs_a.id
  route_table_id = aws_route_table.private.id
}

# ---------------- DB Route (인터넷 경로 없음) ----------------
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
  # 기본 로컬 라우트만 존재 (0.0.0.0/0 추가 금지)
  tags = { Name = "${var.name}-private-db-rt" }
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_c" {
  subnet_id      = aws_subnet.db_c.id
  route_table_id = aws_route_table.db.id
}

# ---------------- (옵션) VPC Endpoints: NAT 비용 절감 ----------------
resource "aws_security_group" "vpce" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name   = "${var.name}-vpce-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-vpce-sg" }
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.enable_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.ecs_a.id]
  security_group_ids  = [aws_security_group.vpce[0].id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.ecs_a.id]
  security_group_ids  = [aws_security_group.vpce[0].id]
}

resource "aws_vpc_endpoint" "logs" {
  count               = var.enable_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.ecs_a.id]
  security_group_ids  = [aws_security_group.vpce[0].id]
}

resource "aws_vpc_endpoint" "ssm" {
  count               = var.enable_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.ecs_a.id]
  security_group_ids  = [aws_security_group.vpce[0].id]
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]  # ECS 프라이빗 RT에 연결
}
