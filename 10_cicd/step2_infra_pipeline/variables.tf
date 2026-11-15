variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름 접두사 (step1과 같은 값이어야 함)"
  type        = string
  default     = "aws-tf-cicd"
}

variable "repo_name" {
  description = "인프라 코드용 CodeCommit 리포지토리 이름"
  type        = string
  default     = "aws-terraform-cicd"
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
