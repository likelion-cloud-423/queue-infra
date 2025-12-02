resource "aws_eks_node_group" "team3_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  capacity_type  = "ON_DEMAND"
  instance_types = var.node_instance_types
  ami_type       = "BOTTLEROCKET_ARM_64"

  tags = {
    Name = "${var.cluster_name}-node-group"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_policy
  ]
}
