resource "aws_eip" "nat" {
  vpc  = true
  tags = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id
  tags          = merge(var.tags, { Name = "${var.name}-nat" })
}
