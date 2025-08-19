output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public_a.id
}

output "ecs_subnet_id" {
  value = aws_subnet.ecs_a.id
}

output "db_subnet_ids" {
  value = [aws_subnet.db_a.id, aws_subnet.db_c.id]
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "db_route_table_id" {
  value = aws_route_table.db.id
}
