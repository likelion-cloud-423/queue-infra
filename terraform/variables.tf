variable "name_prefix" {
  type    = string
  default = "team3"

}

variable "vpc_cidr" {
  type    = string
  default = "10.23.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.23.1.0/24", "10.23.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.23.11.0/24", "10.23.12.0/24"]
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "cluster_version" {
  description = "EKS Kubernetes control plane version"
  type        = string
  default     = "1.34"
}

# =============================================================================
# Queue System 설정
# =============================================================================

variable "queue_system_enabled" {
  description = "Queue System 앱 배포 활성화"
  type        = bool
  default     = true
}

variable "ecr_registry" {
  description = "ECR Registry URL"
  type        = string
  default     = "061039804626.dkr.ecr.ap-northeast-2.amazonaws.com"
}

variable "queue_api_image_tag" {
  description = "queue-api 이미지 태그"
  type        = string
  default     = "latest"
}

variable "queue_manager_image_tag" {
  description = "queue-manager 이미지 태그"
  type        = string
  default     = "latest"
}

variable "chat_server_image_tag" {
  description = "chat-server 이미지 태그"
  type        = string
  default     = "latest"
}

variable "queue_api_replicas" {
  description = "queue-api 레플리카 수"
  type        = number
  default     = 3
}

variable "queue_api_max_replicas" {
  description = "queue-api HPA 최대 레플리카 수"
  type        = number
  default     = 100
}
