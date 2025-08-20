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

output "alb_sg_id" {
  value       = try(aws_security_group.alb[0].id, null)
  description = "ALB security group ID (null if create_sg_bundle=false)"
}

output "ecs_sg_id" {
  value       = try(aws_security_group.ecs[0].id, null)
  description = "ECS tasks security group ID (null if create_sg_bundle=false)"
}

output "db_sg_id" {
  value       = try(aws_security_group.db[0].id, null)
  description = "DB security group ID (null if create_sg_bundle=false)"
}

output "vpce_sg_id" {
  value       = var.enable_vpc_endpoints ? aws_security_group.vpce[0].id : null
  description = "VPC endpoints SG (null if endpoints disabled)"
}

