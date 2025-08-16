# EIP for NAT (v5+: vpc 대신 domain="vpc")
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}

# NAT Gateway in the public subnet
resource "aws_nat_gateway" "this" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = var.public_subnet_id
  connectivity_type = "public" # 명시(기본 public이지만 안전하게)

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}
