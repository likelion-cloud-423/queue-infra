variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes and cluster ENI"
  type        = list(string)
}
