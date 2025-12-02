#EC2 Worker Node가 사용할 IAM Role 생성
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

# EC2 인스턴스만 이 Role을 사용할 수 있게 지정
data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 워커 노드가 EKS Control Plane과 연결되는 데 필요한 필수 권한
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# pod에게 ip를 할당하기 위한 권한. 하나의 파드는 하나의 ip를 가지기 때문이다
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Worker Node가 ECR에서 Docker 이미지를 가져오기 위한 권한
resource "aws_iam_role_policy_attachment" "ecr_read_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EBS CSI Driver 권한 추가
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
