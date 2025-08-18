resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-pg"
  family      = "postgres${replace(var.engine_version, "/\\..*$/", "")}"
  description = "Parameter group for ${var.name}"
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-pg"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  username                = var.username
  password                = var.password
  db_name                 = var.db_name
  allocated_storage       = var.allocated_storage
  storage_encrypted       = false

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.db_sg_id]

  backup_retention_period = 0
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  parameter_group_name    = aws_db_parameter_group.this.name
}
