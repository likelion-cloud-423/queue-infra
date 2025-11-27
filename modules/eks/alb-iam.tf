resource "aws_iam_policy" "alb_controller_policy" {
  name = "${var.cluster_name}-alb-controller-policy"

  policy = data.aws_iam_policy_document.alb_policy.json
}

data "aws_iam_policy_document" "alb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:CreateSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloadbalancing:*",
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
  }
}
