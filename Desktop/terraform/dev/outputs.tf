# 편의 출력
output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_id" { value = module.vpc.public_subnet_id }
output "ecs_subnet_id" { value = module.vpc.ecs_subnet_id }
output "db_subnet_ids" { value = module.vpc.db_subnet_ids }
output "public_route_table_id" { value = module.vpc.public_route_table_id }
output "private_route_table_id" { value = module.vpc.private_route_table_id }
output "db_route_table_id" { value = module.vpc.db_route_table_id }

