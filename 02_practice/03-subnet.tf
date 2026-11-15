# ============================================================
# 03-subnet.tf — 서브넷 (Subnet)
# VPC의 IP 대역을 가용영역별로 나눈 구획.
# - 퍼블릭: IGW로 직접 나가는 서브넷 (map_public_ip_on_launch = true)
# - 프라이빗: 외부 직접 접근 불가, NGW 경유 아웃바운드만 가능
# 배치 규칙: AZ당 pub 1개 + pri 1개 — 2개 AZ라 총 4개
# ============================================================

# Public Subnet — ap-northeast-2a
resource "aws_subnet" "terraform_pub_subnet_2a" {
  vpc_id                  = aws_vpc.terraform_vpc.id # 어느 VPC 안에 만들지
  cidr_block              = "10.200.1.0/24"          # VPC 대역(10.200.0.0/16) 안의 /24
  availability_zone       = "ap-northeast-2a"        # 서브넷은 반드시 1개 AZ에 소속
  map_public_ip_on_launch = true                     # 이 서브넷의 인스턴스에 공인 IP 자동 부여

  tags = {
    Name = "terraform-pub-subnet-2a"
  }
}

# Public Subnet — ap-northeast-2c (다른 AZ — 장애 대비 이중화의 기본)
resource "aws_subnet" "terraform_pub_subnet_2c" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = "10.200.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-pub-subnet-2c"
  }
}

# Private Subnet — ap-northeast-2a
resource "aws_subnet" "terraform_pri_subnet_2a" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.200.11.0/24" # pub과 겹치지 않는 대역으로 구분
  availability_zone = "ap-northeast-2a"
  # map_public_ip_on_launch 생략 = false — 공인 IP가 없어 외부에서 직접 접근 불가

  tags = {
    Name = "terraform-pri-subnet-2a"
  }
}

# Private Subnet — ap-northeast-2c
resource "aws_subnet" "terraform_pri_subnet_2c" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.200.12.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "terraform-pri-subnet-2c"
  }
}
