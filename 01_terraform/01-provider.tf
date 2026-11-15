# ============================================================
# 01_provider.tf — Terraform 코어·프로바이더 선언
# - terraform 블록: 실행에 필요한 코어 버전과 프로바이더를 고정
# - provider 블록: 실제 AWS 접속 설정 (리전)
# 인증 정보는 코드에 적지 않고 ~/.aws 자격증명 또는 환경변수를 사용
# ============================================================

terraform {
  required_version = ">= 1.0.0, <2.0.0" # Terraform 1.x 버전대만 허용

  required_providers {
    aws = {
      source  = "hashicorp/aws" # 레지스트리 주소 (네임스페이스/이름)
      version = "~> 5.0"        # 5.x만 허용 — 6.0 메이저 변경 차단
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # Asia Pacific (Seoul)
}
