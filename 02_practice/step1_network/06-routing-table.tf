# ============================================================
# 06-routing-table.tf — 라우팅 테이블·라우팅·서브넷 연결
#
# 구조도:
#   10.200.0.0/16 VPC
#   │
#   ├─ Subnet: 10.200.1.0/24 (terraform_pub_subnet_2a)
#   │     └─ Route Table: terraform_pub_rt → IGW
#   ├─ Subnet: 10.200.2.0/24 (terraform_pub_subnet_2c)
#   │     └─ Route Table: terraform_pub_rt → IGW
#   │
#   ├─ Subnet: 10.200.11.0/24 (terraform_pri_subnet_2a)
#   │     └─ Route Table: terraform_pri_rt → NAT GW
#   └─ Subnet: 10.200.12.0/24 (terraform_pri_subnet_2c)
#         └─ Route Table: terraform_pri_rt → NAT GW
#
# 흐름: route_table 생성 → route(목적지 경로) 추가 → 서브넷에 association
# ============================================================

# 라우팅 테이블 — 서브넷 트래픽의 목적지 규칙을 담는 컨테이너
resource "aws_route_table" "terraform_pub_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    "Name" = "terraform-pub-rt"
  }
}

resource "aws_route_table" "terraform_pri_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    "Name" = "terraform-pri-rt"
  }
}

# 라우팅 — 퍼블릭: 모든 외부 트래픽(0.0.0.0/0)을 IGW로 보냄
resource "aws_route" "terraform_pub_rt" {
  route_table_id         = aws_route_table.terraform_pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.terraform_igw.id
}

# 라우팅 — 프라이빗: 외부로 나가는 트래픽은 NAT 게이트웨이 경유
# (인터넷→내부 방향의 신규 연결은 불가, 내부→외부 응답만 통과)
resource "aws_route" "terraform_pri_rt" {
  route_table_id         = aws_route_table.terraform_pri_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.terraform_ngw.id
}

# 명시적 서브넷 연결 — 테이블과 서브넷을 짝지어야 규칙이 실제로 적용됨
resource "aws_route_table_association" "terraform_pub_rt_associate_2a" {
  subnet_id      = aws_subnet.terraform_pub_subnet_2a.id
  route_table_id = aws_route_table.terraform_pub_rt.id
}

resource "aws_route_table_association" "terraform_pub_rt_associate_2c" {
  subnet_id      = aws_subnet.terraform_pub_subnet_2c.id
  route_table_id = aws_route_table.terraform_pub_rt.id
}

resource "aws_route_table_association" "terraform_pri_rt_associate_2a" {
  subnet_id      = aws_subnet.terraform_pri_subnet_2a.id
  route_table_id = aws_route_table.terraform_pri_rt.id
}

resource "aws_route_table_association" "terraform_pri_rt_associate_2c" {
  subnet_id      = aws_subnet.terraform_pri_subnet_2c.id
  route_table_id = aws_route_table.terraform_pri_rt.id
}
