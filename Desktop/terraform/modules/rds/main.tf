resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.name}-rds-subnet-group"
  subnet_ids = var.private_subnet_db_ids
  tags       = { Name = "${var.name}-rds-subnet-group" }
}

resource "aws_db_instance" "rds" {
  identifier     = "${var.name}-rds"
  engine         = var.engine
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_encrypted = var.storage_encrypted

  username = var.db_username
  password = var.db_password          # ★ 항상 이 값 사용
  # manage_master_user_password 속성 자체를 쓰지 않음 (충돌 방지)

  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  apply_immediately       = var.apply_immediately
  skip_final_snapshot     = var.skip_final_snapshot

  tags = { Name = "${var.name}-rds" }
}
