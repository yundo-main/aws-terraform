# ============================================================
# versions.tf — 코어·프로바이더 버전 고정
# - required_version: Terraform 실행 파일 버전 범위
# - required_providers: provider 소스·버전 — lock 파일과 쌍
# ============================================================

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
