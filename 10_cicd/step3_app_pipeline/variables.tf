variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름 접두사 (step1·2와 같은 값이어야 함)"
  type        = string
  default     = "aws-tf-cicd"
}

variable "app_name" {
  description = "배포할 앱 이름 — ECR 리포·k8s deployment 이름"
  type        = string
  default     = "sample-app"
}

variable "app_repo_name" {
  description = "앱 소스용 CodeCommit 리포지토리 이름"
  type        = string
  default     = "sample-app-src"
}

variable "repo_branch" {
  description = "파이프라인이 감지할 브랜치"
  type        = string
  default     = "main"
}

variable "eks_cluster_name" {
  description = "배포 대상 EKS 클러스터 (02_practice step3의 클러스터)"
  type        = string
  default     = "terraform-eks-cluster"
}
