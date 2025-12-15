output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "target_group_arns" {
  value = module.alb.target_group_arns
}

output "db_endpoint" {
  value = module.rds.db_address
}
