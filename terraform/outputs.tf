output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "valkey_endpoint" {
  description = "ElastiCache Valkey primary endpoint"
  value       = aws_elasticache_replication_group.valkey.primary_endpoint_address
}

# =============================================================================
# Observability Outputs
# =============================================================================

output "prometheus_url" {
  description = "Prometheus server URL"
  value       = "http://prometheus-server.observability.svc.cluster.local"
}

output "grafana_url" {
  description = "Grafana URL (get from ALB after deployment)"
  value       = "Run: kubectl get ingress grafana -n observability"
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
# Queue System Outputs
# =============================================================================

output "queue_system_url" {
  description = "Queue System URL (get from ALB after deployment)"
  value       = "Run: kubectl get ingress queue-ingress -n queue-system"
}
