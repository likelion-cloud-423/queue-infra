###############################################
# EKS NODE SECURITY GROUP
###############################################

resource "aws_security_group" "eks_node_sg" {
  name        = "${var.name_prefix}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-eks-node-sg"
  }
}

resource "aws_security_group_rule" "eks_node_ingress_from_alb" {
  description              = "Allow ALB to NodePort"
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "eks_node_ingress_http_https_from_alb" {
  description              = "Allow ALB to Node 80-443"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}


###############################################
# ALB SECURITY GROUP
###############################################

resource "aws_security_group" "alb_sg" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}


###############################################
# REDIS SECURITY GROUP
###############################################

resource "aws_security_group" "redis_sg" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-redis-sg"
  }
}

resource "aws_security_group_rule" "redis_ingress_from_eks" {
  description              = "Allow EKS Node to Redis 6379"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis_sg.id
  source_security_group_id = aws_security_group.eks_node_sg.id
}
