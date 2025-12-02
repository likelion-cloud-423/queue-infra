# EKS NODE SECURITY GROUP
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

  depends_on = [module.vpc]
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


# ALB SECURITY GROUP


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

  depends_on = [module.vpc]
}


# VALKEY SECURITY GROUP
resource "aws_security_group" "valkey_sg" {
  name        = "${var.name_prefix}-valkey-sg"
  description = "Security group for valkey"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-valkey-sg"
  }

  depends_on = [module.vpc]
}

resource "aws_security_group_rule" "valkey_ingress_from_eks" {
  description = "Allow EKS (cluster SG) to valkey 6379"
  type        = "ingress"
  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"


  security_group_id = aws_security_group.valkey_sg.id


  source_security_group_id = data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id

  depends_on = [module.eks, data.aws_eks_cluster.this]
}
