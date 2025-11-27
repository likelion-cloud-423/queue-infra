resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}-redis-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "redis-${var.name_prefix}"
  description                   = "Production Redis Replication Group"

  engine                        = "redis"
  engine_version                = "7.1"
  node_type                     = "cache.m6g.large"
  port                          = 6379

  multi_az_enabled              = true
  automatic_failover_enabled    = true

  num_node_groups               = 1
  replicas_per_node_group       = 1

  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids            = [aws_security_group.redis_sg.id]

  parameter_group_name          = "default.redis7"

  tags = {
    Name = "${var.name_prefix}-redis"
  }
}
