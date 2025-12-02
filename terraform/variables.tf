variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "team3"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.23.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.23.1.0/24", "10.23.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.23.11.0/24", "10.23.12.0/24"]
}

variable "cluster_version" {
  description = "EKS Kubernetes control plane version"
  type        = string
  default     = "1.34"
}

# =============================================================================
# EKS Node Group
# =============================================================================

variable "node_instance_types" {
  description = "EC2 instance types for EKS node group"
  type        = list(string)
  default     = ["t4g.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

# =============================================================================
# Valkey (ElastiCache)
# =============================================================================

variable "valkey_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "valkey_multi_az" {
  description = "Enable Multi-AZ for Valkey"
  type        = bool
  default     = false
}

variable "valkey_replicas" {
  description = "Number of replicas per node group"
  type        = number
  default     = 0
}

# =============================================================================
# Observability
# =============================================================================

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