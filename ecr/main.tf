terraform {
  required_version = ">= 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

locals {
  ecr_services = {
    "queue-api"     = "queue-api-ecr"
    "queue-manager" = "queue-manager-ecr"
    "chat-server"   = "chat-server-ecr"
  }
}

resource "aws_ecr_repository" "service" {
  for_each = local.ecr_services

  name = each.key   # 실제 ECR 리포지토리 이름 (queue-api, queue-manager, chat-server)

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = each.value     # 태그 이름 (queue-api-ecr 같은 이름)
    Project = "queue-system"
  }
}
