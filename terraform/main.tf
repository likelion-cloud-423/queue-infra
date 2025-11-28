terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
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

module "eks" {
  source = "./modules/eks"

  cluster_name       = "team3-eks-cluster"
  private_subnet_ids = module.vpc.private_subnet_ids
}

# EKS 클러스터 정보
data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Helm provider가 EKS에 붙도록 설정
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
