terraform {
  required_version = ">= 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source          = "./modules/vpc"
  name_prefix     = var.name_prefix
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

locals {
  public_subnets_map = {
    for idx, subnet_id in module.vpc.public_subnet_ids :
    idx => subnet_id
  }
  cluster_name = "${var.name_prefix}-eks-cluster"
}

# 퍼블릭 서브넷에 ELB 태그 달기
resource "aws_ec2_tag" "public_subnets_elb_role" {
  for_each    = local.public_subnets_map
  resource_id = each.value

  key   = "kubernetes.io/role/elb"
  value = "1"
}

# 퍼블릭 서브넷에 클러스터 태그 달기
resource "aws_ec2_tag" "public_subnets_cluster" {
  for_each    = local.public_subnets_map
  resource_id = each.value

  key   = "kubernetes.io/cluster/${local.cluster_name}"
  value = "shared"
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = local.cluster_name
  private_subnet_ids  = module.vpc.private_subnet_ids
  vpc_id              = module.vpc.vpc_id
  valkey_endpoint     = aws_elasticache_replication_group.valkey.primary_endpoint_address
  cluster_version     = var.cluster_version
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}

data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}
