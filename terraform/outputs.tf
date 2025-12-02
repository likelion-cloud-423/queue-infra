output "vpc_id" {
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
}

output "valkey_endpoint" {
  description = "ElastiCache Valkey primary endpoint"
  value       = aws_elasticache_replication_group.valkey.primary_endpoint_address
}

# =============================================================================
# Observability Outputs
# =============================================================================

output "amp_workspace_id" {
  description = "Amazon Managed Prometheus workspace ID"
  value       = aws_prometheus_workspace.this.id
}

output "amp_workspace_endpoint" {
  description = "Amazon Managed Prometheus workspace endpoint"
  value       = aws_prometheus_workspace.this.prometheus_endpoint
}

output "grafana_workspace_id" {
  description = "Amazon Managed Grafana workspace ID"
  value       = aws_grafana_workspace.this.id
}

output "grafana_workspace_endpoint" {
  description = "Amazon Managed Grafana workspace endpoint URL"
  value       = aws_grafana_workspace.this.endpoint
}

output "alloy_role_arn" {
  description = "IAM Role ARN for Grafana Alloy (IRSA)"
  value       = aws_iam_role.alloy_role.arn
}

output "loki_role_arn" {
  description = "IAM Role ARN for Loki (IRSA)"
  value       = aws_iam_role.loki_role.arn
}

output "loki_s3_bucket" {
  description = "S3 bucket name for Loki storage"
  value       = aws_s3_bucket.loki.id
}

# =============================================================================
# ArgoCD Outputs
# =============================================================================

output "argocd_server_url" {
  description = "ArgoCD server URL (get from ALB after deployment)"
  value       = "Run: kubectl get ingress -n argocd"
}

output "argocd_initial_admin_password" {
  description = "Command to get ArgoCD initial admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
