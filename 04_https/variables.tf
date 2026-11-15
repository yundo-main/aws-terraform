# ============================================================
# variables.tf — 입력 변수
# 이 단계는 03_real이 먼저 apply 되어 있어야 동작합니다
# ============================================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 — 태그·리소스 이름 접두사 (03_real과 동일해야)"
  type        = string
  default     = "terraform"
}

variable "domain_name" {
  description = "인증서를 발급할 도메인 — 03_real의 Route53 존과 같은 도메인이어야 함"
  type        = string
  default     = "jarrod.site"
}

variable "real_state_path" {
  description = "03_real의 terraform.tfstate 경로 — remote_state가 읽을 위치"
  type        = string
  default     = "../03_real/terraform.tfstate"
}
