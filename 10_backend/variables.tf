variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름 접두사 (버킷·테이블 이름에 사용)"
  type        = string
  default     = "aws-tf-cicd"
}
