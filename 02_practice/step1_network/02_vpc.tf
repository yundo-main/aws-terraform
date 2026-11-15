# ============================================================
# 02_vpc.tf — VPC (Virtual Private Cloud)
# 이 인프라 전체가 들어갈 논리적 네트워크 공간
# ============================================================

resource "aws_vpc" "terraform_vpc" {
  cidr_block           = "10.200.0.0/16" # VPC 전체 IP 대역 (약 65,000개 IP)
  enable_dns_support   = true            # VPC 내부 DNS 해석 활성화
  enable_dns_hostnames = true            # 인스턴스에 DNS 호스트명 부여

  tags = {
    "Name" = "terraform-vpc"
  }
}
