# ============================================================
# main.tf — 전체 리소스 (단일 state, 실무 표준 레이아웃)
# locals → VPC → 서브넷 → IGW/NGW → 라우팅 → SG → EC2 → RDS
#        → EKS 노드SG → 클러스터 → 노드그룹 → ECR
#        → Route53 → ALB SG → ALB·리스너
# 02_practice와 같은 리소스 — 값만 var.xxx 참조로 변수화
# ============================================================


# ---------------- 02_vpc.tf ----------------
# 인프라 전체가 들어갈 논리적 네트워크 공간.
# 02와 같은 리소스 — 값만 var.xxx 참조로 바뀐 것을 확인

# VPC — 전체를 담는 논리적 네트워크
resource "aws_vpc" "terraform_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}




# ---------------- 03-subnet.tf ----------------
# AZ당 pub+pri 1쌍 — CIDR·AZ가 var.pub_subnet_cidrs / var.azs로 분리

# 서브넷 — AZ별 IP 구획
resource "aws_subnet" "terraform_pub_subnet_2a" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.pub_subnet_cidrs[0]
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.project_name}-pub-subnet-2a"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}

# 서브넷 — AZ별 IP 구획
resource "aws_subnet" "terraform_pub_subnet_2c" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.pub_subnet_cidrs[1]
  availability_zone       = var.azs[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.project_name}-pub-subnet-2c"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}

# 서브넷 — AZ별 IP 구획
resource "aws_subnet" "terraform_pri_subnet_2a" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.pri_subnet_cidrs[0]
  availability_zone = var.azs[0]

  tags = {
    Name                                          = "${var.project_name}-pri-subnet-2a"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}

# 서브넷 — AZ별 IP 구획
resource "aws_subnet" "terraform_pri_subnet_2c" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.pri_subnet_cidrs[1]
  availability_zone = var.azs[1]

  tags = {
    Name                                          = "${var.project_name}-pri-subnet-2c"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}




# ---------------- 04-igw.tf ----------------
# VPC↔인터넷 출입구 — pub 라우팅의 목적지

# IGW — VPC의 인터넷 출입구
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


# ---------------- 05-ngw.tf ----------------
# pri 서브넷의 아웃바운드 중계 — 반드시 pub 서브넷에 배치

# EIP — NGW가 쓸 고정 공인 IP
resource "aws_eip" "terraform_eip" {
  domain = "vpc"
}

# NGW — pri 아웃바운드 중계 (pub 서브넷에 둠)
resource "aws_nat_gateway" "terraform_ngw" {
  allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.terraform_pub_subnet_2a.id

  tags = {
    Name = "${var.project_name}-ngw"
  }
}




# ---------------- 06-routing-table.tf ----------------
# pub → IGW / pri → NGW — 테이블을 서브넷에 붙여야 적용

# 라우팅 테이블 — 목적지 규칙 컨테이너
resource "aws_route_table" "terraform_pub_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-pub-rt"
  }
}

# 라우팅 테이블 — 목적지 규칙 컨테이너
resource "aws_route_table" "terraform_pri_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-pri-rt"
  }
}

# 라우팅 규칙 — 0.0.0.0/0 목적지
resource "aws_route" "terraform_pub_rt" {
  route_table_id         = aws_route_table.terraform_pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.terraform_igw.id
}

# 라우팅 규칙 — 0.0.0.0/0 목적지
resource "aws_route" "terraform_pri_rt" {
  route_table_id         = aws_route_table.terraform_pri_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.terraform_ngw.id
}

# 테이블↔서브넷 연결 — 붙여야 적용
resource "aws_route_table_association" "terraform_pub_rt_associate_2a" {
  subnet_id      = aws_subnet.terraform_pub_subnet_2a.id
  route_table_id = aws_route_table.terraform_pub_rt.id
}

# 테이블↔서브넷 연결 — 붙여야 적용
resource "aws_route_table_association" "terraform_pub_rt_associate_2c" {
  subnet_id      = aws_subnet.terraform_pub_subnet_2c.id
  route_table_id = aws_route_table.terraform_pub_rt.id
}

# 테이블↔서브넷 연결 — 붙여야 적용
resource "aws_route_table_association" "terraform_pri_rt_associate_2a" {
  subnet_id      = aws_subnet.terraform_pri_subnet_2a.id
  route_table_id = aws_route_table.terraform_pri_rt.id
}

# 테이블↔서브넷 연결 — 붙여야 적용
resource "aws_route_table_association" "terraform_pri_rt_associate_2c" {
  subnet_id      = aws_subnet.terraform_pri_subnet_2c.id
  route_table_id = aws_route_table.terraform_pri_rt.id
}


# Bastion SG — 실습용 전체 개방 (운영에서는 CIDR 축소 권장)


# ---------------- 07-sg-ec2-rds.tf ----------------
# bastion(22·80·443·3306 개방) / rds(3306 — bastion SG만 허용)

# 보안 그룹 — 인스턴스 수준 방화벽
resource "aws_security_group" "terraform_sg_bastion" {
  name        = "${var.project_name}-sg-bastion"
  description = "for Bastion Server"
  vpc_id      = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-sg-bastion"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for ping"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTPS"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for DB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS SG — 배스천 SG를 가진 인스턴스에서만 3306 허용

# 보안 그룹 — 인스턴스 수준 방화벽
resource "aws_security_group" "terraform_sg_rds" {
  name        = "${var.project_name}-sg-rds"
  description = "for RDS MariaDB"
  vpc_id      = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-sg-rds"
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.terraform_sg_bastion.id]
    description     = "MariaDB from bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# ---------------- 08-ec2.tf ----------------
# pub-2a의 SSH 경유 서버 — ami·type·key 전부 변수화

# 배스천 EC2 — SSH 경유 서버
resource "aws_instance" "terraform_pub_ec2_bastion_2a" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  vpc_security_group_ids      = [aws_security_group.terraform_sg_bastion.id]
  subnet_id                   = aws_subnet.terraform_pub_subnet_2a.id
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    tags = {
      Name = "${var.project_name}-pub-ec2-bastion-2a"
    }
  }

  tags = {
    Name = "${var.project_name}-pub-ec2-bastion-2a"
  }
}




# ---------------- 09-rds.tf ----------------
# 서브넷 그룹 → 파라미터 그룹 → 인스턴스 순서

# DB 서브넷 그룹 — RDS 배치 후보 (2AZ 필수)
resource "aws_db_subnet_group" "terraform_rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.terraform_pri_subnet_2a.id, aws_subnet.terraform_pri_subnet_2c.id]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# DB 파라미터 그룹 — 엔진 설정 묶음
resource "aws_db_parameter_group" "terraform_mariadb_parameter_group" {
  name        = "${var.project_name}-mariadb-parameter-group"
  family      = "mariadb10.11"
  description = "Custom parameter group for MariaDB"

  parameter {
    name  = "max_connections"
    value = "150"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  dynamic "parameter" {
    for_each = ["character_set_client", "character_set_connection", "character_set_database",
    "character_set_filesystem", "character_set_results", "character_set_server"]
    content {
      name  = parameter.value
      value = "utf8mb4"
    }
  }

  dynamic "parameter" {
    for_each = ["collation_connection", "collation_server"]
    content {
      name  = parameter.value
      value = "utf8mb4_unicode_ci"
    }
  }

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }
}

# RDS 인스턴스 — 관리형 MariaDB
resource "aws_db_instance" "terraform_mariadb_rds" {
  identifier_prefix      = "${var.project_name}-mariadb-rds"
  allocated_storage      = 10
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.terraform_mariadb_parameter_group.name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.terraform_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.terraform_sg_rds.id]

  tags = {
    Name = "${var.project_name}-mariadb-rds"
  }
}




# ---------------- 11-sg-eks.tf ----------------
# 노드 인스턴스 방화벽 — 클러스터 SG로도 재사용

# 보안 그룹 — 인스턴스 수준 방화벽
resource "aws_security_group" "terraform_sg_eks_node_group" {
  name        = "${var.project_name}-sg-eks-node"
  description = "for EKS-managed server"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for ping"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# ---------------- 12-eks.tf ----------------
# 역할 2개 정책 부착 후 클러스터 생성 — depends_on 필수

# IAM 역할 — 서비스가 맡을 권한
resource "aws_iam_role" "terraform_eks_cluster_role" {
  name = "${var.project_name}_eks_cluster_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# 역할↔관리형 정책 부착
resource "aws_iam_role_policy_attachment" "terraform_eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.terraform_eks_cluster_role.name
}

# 역할↔관리형 정책 부착
resource "aws_iam_role_policy_attachment" "terraform_eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.terraform_eks_cluster_role.name
}


# EKS 클러스터 — 관리형 컨트롤플레인
resource "aws_eks_cluster" "terraform_eks_cluster" {
  name     = "${var.project_name}_eks_cluster"
  role_arn = aws_iam_role.terraform_eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = [aws_subnet.terraform_pri_subnet_2a.id, aws_subnet.terraform_pri_subnet_2c.id]
    endpoint_public_access  = true
    endpoint_private_access = false
    security_group_ids      = [aws_security_group.terraform_sg_eks_node_group.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.terraform_eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.terraform_eks_cluster_AmazonEKSVPCResourceController,
  ]
}




# ---------------- 13-eks-node-group.tf ----------------
# 워커 노드 ASG — 스케일·사양 전부 변수

# IAM 역할 — 서비스가 맡을 권한
resource "aws_iam_role" "terraform_eks_node_group_role" {
  name = "${var.project_name}_eks_node_group_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
    ]
  })
}

# 역할↔관리형 정책 부착
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.terraform_eks_node_group_role.name
}

# 역할↔관리형 정책 부착
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.terraform_eks_node_group_role.name
}

# 역할↔관리형 정책 부착
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.terraform_eks_node_group_role.name
}


# 노드그룹 — 워커 노드 ASG
resource "aws_eks_node_group" "terraform_eks_node_group" {
  cluster_name    = aws_eks_cluster.terraform_eks_cluster.name
  node_group_name = "${var.project_name}_eks_node_group"
  node_role_arn   = aws_iam_role.terraform_eks_node_group_role.arn
  subnet_ids      = [aws_subnet.terraform_pri_subnet_2a.id, aws_subnet.terraform_pri_subnet_2c.id]

  tags = {
    "k8s.io/cluster-autoscaler/enabled"                         = "true"
    "k8s.io/cluster-autoscaler/${var.project_name}_eks_cluster" = "owned"
  }

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  ami_type       = "AL2_x86_64"
  instance_types = var.node_instance_types
  disk_size      = 20

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}




# ---------------- 14-ecr.tf ----------------
# 컨테이너 이미지 저장소 — IMMUTABLE 태그

# ECR — 이미지 저장소
resource "aws_ecr_repository" "terraform_ecr" {
  name                 = "${var.project_name}_ecr"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "${var.project_name}-ecr"
  }
}
# ============================================================





# ---------------- 21-route53.tf ----------------
# domain_name이 비면 전체 건너뜀 (local.domain_enabled)

locals {
  # domain_name이 있으면 Route53 존·레코드 생성
  domain_enabled = var.domain_name != ""
}
# ============================================================



# Route53 호스팅 존 — 도메인 DNS 관리 단위
resource "aws_route53_zone" "route53" {
  count = local.domain_enabled ? 1 : 0
  name  = var.domain_name
}

# DNS 레코드 — 도메인→ALB 연결
resource "aws_route53_record" "app" {
  count   = local.domain_enabled ? 1 : 0
  zone_id = aws_route53_zone.route53[0].zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}


# ---------------- 22-sg-alb.tf ----------------
# SG→SG 참조 체인 — ALB 경유 트래픽만 노드 도달

# 보안 그룹 — 인스턴스 수준 방화벽
resource "aws_security_group" "terraform_sg_alb" {
  name        = "${var.project_name}-sg-alb"
  description = "ALB - allow 80 from internet"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG 규칙 — 다른 SG를 출발지로 참조
resource "aws_security_group_rule" "node_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.terraform_sg_eks_node_group.id
  source_security_group_id = aws_security_group.terraform_sg_alb.id
  from_port                = var.app_node_port
  to_port                  = var.app_node_port
  protocol                 = "tcp"
  description              = "from ALB - NodePort"
}




# ---------------- 24-alb.tf ----------------
# 타깃 = EKS 노드 ASG — 노드 증감에 자동 추적

# ALB — L7 로드밸런서 (pub 서브넷 2곳)
resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform_sg_alb.id]
  subnets            = [aws_subnet.terraform_pub_subnet_2a.id, aws_subnet.terraform_pub_subnet_2c.id]
}

# 타깃그룹 — NodePort로 전달
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-alb-tg"
  port     = var.app_node_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id

  health_check {
    path    = "/"
    matcher = "200-399"
  }
}

# ASG↔타깃그룹 부착 — 자동 등록
resource "aws_autoscaling_attachment" "eks_nodes" {
  autoscaling_group_name = aws_eks_node_group.terraform_eks_node_group.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = aws_lb_target_group.app.arn
}


# 리스너 — 80 포트로 받아 타깃그룹에 전달
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


