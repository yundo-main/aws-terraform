# ============================================================
# variables.tf — 입력 변수
# 02_practice에 하드코딩되어 있던 값들을 변수로 추출
# ============================================================

variable "aws_region" {
  description = "리소스를 생성할 AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "태그와 리소스 이름에 쓸 프로젝트명"
  type        = string
  default     = "terraform"
}

# ---------------- 네트워크 ----------------

variable "vpc_cidr" {
  description = "VPC 전체 IP 대역"
  type        = string
  default     = "10.200.0.0/16"
}

variable "azs" {
  description = "사용할 가용영역 2개"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "pub_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR (azs와 순서 대응)"
  type        = list(string)
  default     = ["10.200.1.0/24", "10.200.2.0/24"]
}

variable "pri_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR (azs와 순서 대응)"
  type        = list(string)
  default     = ["10.200.11.0/24", "10.200.12.0/24"]
}

# ---------------- EC2 ----------------

variable "ec2_ami" {
  description = "배스천 EC2 AMI ID — 리전별로 다름"
  type        = string
  default     = "ami-056a29f2eddc40520"
}

variable "ec2_instance_type" {
  description = "배스천 인스턴스 사양"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 SSH 키페어 이름 — AWS 콘솔에 미리 생성된 것"
  type        = string
  default     = "ja-01-v2"
}

# ---------------- RDS ----------------

variable "db_engine" {
  description = "RDS 엔진"
  type        = string
  default     = "mariadb"
}

variable "db_engine_version" {
  description = "엔진 버전 — 리전에서 지원하는 버전이어야 함"
  type        = string
  default     = "10.11.13"
}

variable "db_instance_class" {
  description = "RDS 인스턴스 사양"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "초기 데이터베이스명 (영문·숫자·_ 만 가능)"
  type        = string
  default     = "terraform_mariadb_rds"
}

variable "db_username" {
  description = "마스터 사용자명"
  type        = string
  default     = "root"
}

variable "db_password" {
  description = "마스터 비밀번호 — 실습용 평문. 운영에서는 tfvars·Secrets Manager 사용"
  type        = string
  sensitive   = true
  default     = "Password1234" # 02와 동일 실습값
}

# ---------------- EKS ----------------

variable "eks_version" {
  description = "EKS 클러스터 버전 — 최신이 꼭 안 되는 경우도 있어 고정"
  type        = string
  default     = "1.32"
}

variable "node_instance_types" {
  description = "노드 인스턴스 사양"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "노드그룹 희망 대수"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "노드그룹 최소 대수"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "노드그룹 최대 대수"
  type        = number
  default     = 4
}

# ---------------- ALB ----------------

variable "domain_name" {
  description = "Route53에 생성할 호스팅 존 도메인 — 비워두면 존·레코드를 건너뛰고 ALB DNS로만 접속"
  type        = string
  default     = "jarrod.site"
}

variable "app_node_port" {
  description = "앱 NodePort — NodePort 서비스의 nodePort 값과 일치해야 함"
  type        = number
  default     = 30080
}
