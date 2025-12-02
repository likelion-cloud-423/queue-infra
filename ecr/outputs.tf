# =============================================================================
# ECR Outputs
# =============================================================================

output "ecr_repository_urls" {
  description = "ECR repository URLs for each service"
  value = {
    for k, v in aws_ecr_repository.service : k => v.repository_url
  }
}

output "ecr_registry" {
  description = "ECR Registry URL (without repository name)"
  value       = split("/", aws_ecr_repository.service["queue-api"].repository_url)[0]
}

output "queue_api_repository_url" {
  description = "queue-api ECR repository URL"
  value       = aws_ecr_repository.service["queue-api"].repository_url
}

output "queue_manager_repository_url" {
  description = "queue-manager ECR repository URL"
  value       = aws_ecr_repository.service["queue-manager"].repository_url
}

output "chat_server_repository_url" {
  description = "chat-server ECR repository URL"
  value       = aws_ecr_repository.service["chat-server"].repository_url
}
