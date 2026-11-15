# ============================================================
# 07-sg-ec2-rds.tf — 보안 그룹 (Security Group)
# 인스턴스 수준의 가상 방화벽. ingress=들어오는 트래픽, egress=나가는 트래픽
# ※ cidr_blocks = 0.0.0.0/0 은 전체 인터넷 허용 — 실습용 설정이며
#   운영 환경에서는 허용 범위를 좁히는 것이 원칙
# ============================================================

# Bastion SG — 배스천(경유 접속용) 서버에 적용할 규칙
resource "aws_security_group" "terraform_sg_bastion" {
  name        = "terraform-sg-bastion"
  description = "for Bastion Server"
  vpc_id      = local.vpc_id
  tags = {
    "Name" = "terraform-sg-bastion"
  }

  # ICMP — ping 응답 허용 (네트워크 연결 확인용)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for ping"
  }

  # SSH — 원격 접속용 22번 포트
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for SSH"
  }

  # HTTP — 웹 서비스 80번 포트
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTP"
  }

  # HTTPS — 웹 서비스 443번 포트
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTPS"
  }

  # MySQL/MariaDB — DB 접속용 3306번 포트
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for DB"
  }

  # 아웃바운드는 전부 허용 — 패키지 설치·외부 API 호출 등을 위해
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 = 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS SG — MariaDB에 적용할 규칙
# 배스천 SG를 가진 인스턴스에서만 3306 접속 허용 (IP 대역이 아닌 SG 참조)
resource "aws_security_group" "terraform_sg_rds" {
  name        = "terraform-sg-rds"
  description = "for RDS MariaDB"
  vpc_id      = local.vpc_id
  tags = {
    "Name" = "terraform-sg-rds"
  }

  # 배스천 서버에서 오는 DB 접속만 허용
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.terraform_sg_bastion.id]
    description     = "MariaDB from bastion"
  }

  # 아웃바운드 전부 허용 (패치·로그 전송 등)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
