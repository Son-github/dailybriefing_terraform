output "vpc_id"            { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [aws_subnet.public_a.id, aws_subnet.public_c.id] }
output "app_subnet_id"     { value = aws_subnet.app_a.id }
output "db_subnet_ids"     { value = [aws_subnet.db_a.id, aws_subnet.db_c.id] }
