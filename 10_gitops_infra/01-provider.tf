# ============================================================
# 01-provider.tf — Terraform 코어·프로바이더 선언
# ============================================================

terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "aws-tf"
      Stage     = "10_gitops_infra"
      ManagedBy = "terraform"
    }
  }
}

# 호출자 정보 — 계정 ID 참조용
data "aws_caller_identity" "current" {}
