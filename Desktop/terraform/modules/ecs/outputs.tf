output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_security_group_id" {
  value = var.ecs_security_group_id
}

output "service_names" {
  value = keys(var.services)
}

output "task_definition_arns" {
  value = { for k, td in aws_ecs_task_definition.svc : k => td.arn }
}
