variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes and cluster ENI"
  type        = list(string)
}

variable "valkey_endpoint" {
  type        = string
  description = "Primary endpoint of Valkey (ElastiCache)"
}

variable "cluster_version" {
  description = "EKS Kubernetes control plane version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for EKS cluster"
  type        = string
}

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
