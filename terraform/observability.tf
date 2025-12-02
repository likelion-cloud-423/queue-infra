# =============================================================================
# Amazon Managed Service for Prometheus (AMP)
# =============================================================================

resource "aws_prometheus_workspace" "this" {
  alias = "${var.name_prefix}-prometheus"

  tags = {
    Name    = "${var.name_prefix}-prometheus"
    Project = "queue-system"
  }
}

# =============================================================================
# S3 Bucket for Loki Storage
# =============================================================================

resource "aws_s3_bucket" "loki" {
  bucket = "${var.name_prefix}-loki-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.name_prefix}-loki-logs"
    Project = "queue-system"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_caller_identity" "current" {}

# =============================================================================
# Grafana Alloy IAM Role (IRSA)
# =============================================================================

resource "aws_iam_role" "alloy_role" {
  name = "${var.name_prefix}-alloy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider_url}:sub" = "system:serviceaccount:observability:alloy"
            "${module.eks.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.name_prefix}-alloy-role"
    Project = "queue-system"
  }
}

# Alloy가 AMP에 메트릭을 쓸 수 있도록 권한 부여
resource "aws_iam_role_policy" "alloy_prometheus_write_policy" {
  name = "${var.name_prefix}-alloy-prometheus-write-policy"
  role = aws_iam_role.alloy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.this.arn
      }
    ]
  })
}

# =============================================================================
# Loki IAM Role (IRSA)
# =============================================================================

resource "aws_iam_role" "loki_role" {
  name = "${var.name_prefix}-loki-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider_url}:sub" = "system:serviceaccount:observability:loki"
            "${module.eks.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.name_prefix}-loki-role"
    Project = "queue-system"
  }
}

# Loki가 S3에 접근할 수 있도록 권한 부여
resource "aws_iam_role_policy" "loki_s3_policy" {
  name = "${var.name_prefix}-loki-s3-policy"
  role = aws_iam_role.loki_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.loki.arn,
          "${aws_s3_bucket.loki.arn}/*"
        ]
      }
    ]
  })
}
