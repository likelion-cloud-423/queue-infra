# 1. EKS OIDC 지문 확인
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# 2. IAM에게 OIDC 등록
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

# 3. 신뢰 관계 설정 (Trust Policy)
data "aws_iam_policy_document" "alb_controller_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

# 4. 역할(Role) 생성
resource "aws_iam_role" "alb_controller_role" {
  name               = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume.json
}

# 5. 정책(Policy) 생성
resource "aws_iam_policy" "alb_controller_policy" {
  name   = "${var.cluster_name}-alb-controller-policy"
  policy = file("${path.module}/iam_policy.json")
}

# 6. 연결(Attachment)
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

# 7. (선택) ARN 출력 - Helm 설치할 때 필요함
output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller_role.arn
}

# 🔥 여기부터 Helm으로 ALB Controller 설치
resource "helm_release" "alb_controller" {
  depends_on = [
    aws_iam_role_policy_attachment.alb_controller_policy_attach
  ]

  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1"

  # --set clusterName=team3-eks-cluster
  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.name
  }

  # --set serviceAccount.create=true
  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  # --set serviceAccount.name=aws-load-balancer-controller
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # --set region=ap-northeast-2
  set {
    name  = "region"
    value = "ap-northeast-2"
  }

  # --set vpcId=...
  set {
    name  = "vpcId"
    value = aws_eks_cluster.this.vpc_config[0].vpc_id
  }

  # --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="ROLE_ARN"
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller_role.arn
  }
}


