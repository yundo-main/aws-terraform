# ============================================================
# 04-igw.tf — 인터넷 게이트웨이 (IGW)
# VPC와 인터넷 사이의 출입구.
# 퍼블릭 서브넷이 외부와 통신하려면 IGW + 라우팅 테이블의 0.0.0.0/0 경로가 필요
# ============================================================

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id # 이 VPC에 IGW를 연결

  tags = {
    Name = "terraform-igw" # AWS 태그 값은 하이픈 OK
  }
}
