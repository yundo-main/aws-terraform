# ============================================================
# 08-ec2.tf — EC2 인스턴스 (배스천 서버)
#
# - Elastic Compute Cloud의 약자로 AWS에서 제공하는 **가상 서버** 서비스
# - 사용자가  설정한 성능과 크기의 가상 서버를 생성하고, 관리하며, 사용한 만큼 비용을 지불
#
# 배스천(Bastion): 외부에서 프라이빗 서브넷 내부로 들어가기 위한 경유 서버.
# 퍼블릭 서브넷에 두고 SSH로 접속한 뒤 내부 리소스로 다시 접속한다.
# ============================================================

resource "aws_instance" "terraform_pub_ec2_bastion_2a" {
  ami                         = "ami-056a29f2eddc40520" # 리전별로 AMI ID가 다름 — ap-northeast-2용
  instance_type               = "t2.micro"              # 프리티어 대상 사양
  vpc_security_group_ids      = [aws_security_group.terraform_sg_bastion.id]
  subnet_id                   = aws_subnet.terraform_pub_subnet_2a.id
  key_name                    = "ja-01-v2" # AWS 콘솔에 미리 생성된 키페어 이름
  associate_public_ip_address = true       # 퍼블릭 IP 부여 — 외부 SSH 접속용

  root_block_device {
    volume_size = "8"   # 루트 디스크 8GB
    volume_type = "gp2" # 범용 SSD 타입
    tags = {
      "Name" = "terraform-pub-ec2-bastion-2a"
    }
  }

  tags = {
    "Name" = "terraform-pub-ec2-bastion-2a"
  }
}
