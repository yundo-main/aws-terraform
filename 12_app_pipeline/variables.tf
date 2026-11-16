variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름 접두사 (10_backend·11_infra_pipeline과 같은 값이어야 함)"
  type        = string
  default     = "aws-tf-cicd"
}

variable "app_name" {
  description = "배포할 앱 이름 — ECR 리포·k8s deployment 이름"
  type        = string
  default     = "sample-app"
}

variable "github_repo" {
  description = "앱 소스 GitHub 리포 — owner/repo 형식 (인프라와 같은 리포, 브랜치로 분리)"
  type        = string
  default     = "yundo-main/aws-terraform"
}

variable "repo_branch" {
  description = "앱 파이프라인이 감지할 브랜치 — 개발(dev), 운영(main)과 분리"
  type        = string
  default     = "dev"
}

variable "eks_cluster_name" {
  description = "배포 대상 EKS 클러스터 (03_real의 클러스터)"
  type        = string
  default     = "terraform-eks-cluster"
}
