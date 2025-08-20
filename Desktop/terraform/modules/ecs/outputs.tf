output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "task_role_arn" {
  value = aws_iam_role.task_role.arn
}

output "execution_role_arn" {
  value = aws_iam_role.task_execution.arn
}

output "log_groups" {
  value = { for k, lg in aws_cloudwatch_log_group.svc : k => lg.name }
}
