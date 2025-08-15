# Public
resource "aws_subnet" "public" {
  count                   = length(var.public_names)
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = var.public_azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = var.public_names[count.index],
    Tier = "public"
  })
}

# Private App
resource "aws_subnet" "app" {
  count             = length(var.app_names)
  vpc_id            = var.vpc_id
  cidr_block        = var.app_cidrs[count.index]
  availability_zone = var.app_azs[count.index]
  tags = merge(var.tags, {
    Name = var.app_names[count.index],
    Tier = "private-app"
  })
}

# Private DB
resource "aws_subnet" "db" {
  count             = length(var.db_names)
  vpc_id            = var.vpc_id
  cidr_block        = var.db_cidrs[count.index]
  availability_zone = var.db_azs[count.index]
  tags = merge(var.tags, {
    Name = var.db_names[count.index],
    Tier = "private-db"
  })
}
