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
