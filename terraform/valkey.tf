resource "aws_elasticache_subnet_group" "valkey_subnet_group" {
  name       = "${var.name_prefix}-valkey-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}-valkey-subnet-group"
  }

  depends_on = [module.vpc]
}

resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id = "valkey-${var.name_prefix}"
  description          = "${var.environment} Valkey Replication Group"

  engine         = "valkey"
  engine_version = "8.0"
  node_type      = var.valkey_node_type
  port           = 6379

  multi_az_enabled           = var.valkey_multi_az
  automatic_failover_enabled = var.valkey_multi_az

  num_node_groups         = 1
  replicas_per_node_group = var.valkey_replicas

  subnet_group_name  = aws_elasticache_subnet_group.valkey_subnet_group.name
  security_group_ids = [aws_security_group.valkey_sg.id]

  parameter_group_name = "default.valkey8"

  tags = {
    Name        = "${var.name_prefix}-valkey"
    Environment = var.environment
  }
}
