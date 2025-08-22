locals {
  effective_db_subnet_ids = length(var.db_subnet_ids) > 0 ? var.db_subnet_ids : var.private_subnet_db_ids
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = local.effective_db_subnet_ids
  tags       = { Name = "${var.name}-db-subnet-group" }
}

resource "aws_db_instance" "rds" {
  identifier             = "${var.name}-rds"
  engine                 = var.engine

  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_encrypted      = var.storage_encrypted

  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.rds_sg_id]

  publicly_accessible     = var.publicly_accessible
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  apply_immediately       = var.apply_immediately
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  tags = { Name = "${var.name}-rds" }
}
