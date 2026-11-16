variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름 접두사 (버킷·테이블·파이프라인 이름에 사용)"
  type        = string
  default     = "aws-tf-cicd"
}

variable "github_repo" {
  description = "파이프라인 소스 GitHub 리포 — owner/repo 형식"
  type        = string
  default     = "yundo-main/aws-terraform"
}

variable "repo_branch" {
  description = "파이프라인이 감지할 브랜치"
  type        = string
  default     = "main"
}

variable "tf_dir" {
  description = "리포 안에서 terraform을 실행할 디렉터리 (배포 대상 코드 위치)"
  type        = string
  default     = "03_real"
}

variable "tf_version" {
  description = "CodeBuild에 설치할 Terraform 버전"
  type        = string
  default     = "1.9.8"
}

variable "state_key" {
  description = "S3 backend에 저장할 state 경로"
  type        = string
  default     = "03_real/terraform.tfstate"
}
