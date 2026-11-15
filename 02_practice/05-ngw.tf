# ============================================================
# 05-ngw.tf — NAT 게이트웨이 + EIP
#
# **NGW**
#
# NAT Gateway의 약자로 VPC 내에서 프라이빗 서브넷에 있는 리소스들이 인터넷에 접근할 수 있도록 도와주는 서비스
# NAT는 Network Address Translation : 프라이빗 네트워크의 사설 IP를 공인 IP로 변환하여 외부와의 통신을 가능하게 함
#
# **EIP**
# NAT Gateway에 고정된 퍼블릭 IP 주소를 제공
# EIP가 없으면 NAT Gateway가 인터넷과 연결되지 않고, 프라이빗 서브넷에 있는 리소스는 외부와 통신이 불가함
# ============================================================

# Elastic IP — NAT 게이트웨이가 외부에 보여줄 고정 공인 IP
resource "aws_eip" "terraform_eip" {
  domain = "vpc"
}

# NAT 게이트웨이 — 반드시 "퍼블릭" 서브넷에 배치해야 프라이빗 서브넷의
# 아웃바운드 트래픽을 중계할 수 있다
resource "aws_nat_gateway" "terraform_ngw" {
  allocation_id = aws_eip.terraform_eip.id # 위에서 만든 EIP를 이 NGW에 연결
  subnet_id     = aws_subnet.terraform_pub_subnet_2a.id
  tags = {
    "Name" = "terraform-ngw"
  }
}
