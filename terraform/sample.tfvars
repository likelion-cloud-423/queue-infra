# =============================================================================
# Environment Template - Copy this file and customize for your environment
# =============================================================================
#
# Usage:
#   1. Copy this file: cp sample.tfvars myenv.tfvars
#   2. Update values for your environment
#   3. Deploy: terraform apply -var-file=myenv.tfvars
#

# Environment name (used for tagging and naming)
environment = "dev"  # dev, staging, prod, etc.

# Resource name prefix
name_prefix = "team3-dev"

# =============================================================================
# EKS Node Group Configuration
# =============================================================================

# EC2 instance types for worker nodes
# Examples:
#   - Dev: ["t4g.small"]
#   - Prod: ["t4g.large", "t4g.xlarge"]
node_instance_types = ["t4g.small"]

# Number of nodes (desired state)
node_desired_size = 2

# Minimum number of nodes (for autoscaling)
node_min_size = 2

# Maximum number of nodes (for autoscaling)
node_max_size = 3

# =============================================================================
# Valkey (Redis) Configuration
# =============================================================================

# ElastiCache node type
# Examples:
#   - Dev: cache.t4g.micro
#   - Prod: cache.t4g.small, cache.t4g.medium
valkey_node_type = "cache.t4g.micro"

# Enable Multi-AZ deployment for high availability
# Dev: false (single node, lower cost)
# Prod: true (multi-AZ, automatic failover)
valkey_multi_az = false

# Number of read replicas per node group
# Must be 0 when valkey_multi_az = false
# Min 1 when valkey_multi_az = true
valkey_replicas = 0

# =============================================================================
# Grafana Admin Credentials
# =============================================================================

grafana_admin_user     = "admin"
grafana_admin_password = "changeme-strong-password"

# =============================================================================
# Network Configuration (Optional - defaults in variables.tf)
# =============================================================================

# vpc_cidr        = "10.23.0.0/16"
# azs             = ["ap-northeast-2a", "ap-northeast-2c"]
# public_subnets  = ["10.23.1.0/24", "10.23.2.0/24"]
# private_subnets = ["10.23.11.0/24", "10.23.12.0/24"]

# =============================================================================
# EKS Version (Optional - default in variables.tf)
# =============================================================================

# cluster_version = "1.34"
