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
  vpc_cidr        = "10.23.0.0/16"
  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.23.1.0/24", "10.23.2.0/24"]
  private_subnets = ["10.23.11.0/24", "10.23.12.0/24"]
}

locals {
  public_subnets_map = {
    for idx, subnet_id in module.vpc.public_subnet_ids :
    idx => subnet_id
  }
}

# 퍼블릭 서브넷에 태그 달기 일단은 다시 활성화해보자.. 오류가 날 수도 있긴 함
resource "aws_ec2_tag" "public_subnets_elb_role" {
  for_each    = local.public_subnets_map
  resource_id = each.value

  key   = "kubernetes.io/role/elb"
  value = "1"
}

#  클러스터 태그 달기
resource "aws_ec2_tag" "public_subnets_cluster" {
  for_each    = local.public_subnets_map
  resource_id = each.value

  key   = "kubernetes.io/cluster/team3-eks-cluster"
  value = "shared"
}


/*
# VPC 모듈에서 나온 public_subnet_ids를 "고정 키 → 서브넷 ID" 맵으로 변환
locals {
  public_subnets_map = {
    for idx, subnet_id in module.vpc.public_subnet_ids :
    idx => subnet_id
  }
}

# 퍼블릭 서브넷에 태그 달기 (ELB 용)
resource "aws_ec2_tag" "public_subnets_elb_role" {
  for_each    = local.public_subnets_map
  resource_id = each.value

  key   = "kubernetes.io/role/elb"
  value = "1"
}

# 클러스터 태그 달기
resource "aws_ec2_tag" "public_subnets_cluster" {
  for_each    = local.public_subnets_map
  resource_id = each.value

  key   = "kubernetes.io/cluster/team3-eks-cluster"
  value = "shared"
}
*/




# 🔹 Valkey 엔드포인트를 EKS 모듈에 넘겨줌
module "eks" {
  source = "./modules/eks"

  cluster_name       = "team3-eks-cluster"
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  valkey_endpoint    = aws_elasticache_replication_group.valkey.primary_endpoint_address
  cluster_version    = var.cluster_version
}

# EKS 클러스터 정보
data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# data "aws_eks_cluster_auth" "this" {
#   name       = module.eks.cluster_name
#   depends_on = [module.eks]
# }

# ✅ kubernetes provider (k8s-secret-valkey.tf 에서 사용)
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

# Helm provider – 그대로 유지
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
