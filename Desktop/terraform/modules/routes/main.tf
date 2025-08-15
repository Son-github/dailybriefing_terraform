# Public RT → IGW
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

# Private RT → NAT
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# App + DB 전체를 하나의 Private RT에 연결
locals {
  all_private_ids = concat(var.app_subnet_ids, var.db_subnet_ids)
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(local.all_private_ids)
  subnet_id      = local.all_private_ids[count.index]
  route_table_id = aws_route_table.private.id
}
