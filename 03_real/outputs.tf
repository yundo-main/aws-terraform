# ============================================================
# outputs.tf — apply 후 확인할 값
# ============================================================

output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.terraform_vpc.id
}

output "pub_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = [aws_subnet.terraform_pub_subnet_2a.id, aws_subnet.terraform_pub_subnet_2c.id]
}

output "pri_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value       = [aws_subnet.terraform_pri_subnet_2a.id, aws_subnet.terraform_pri_subnet_2c.id]
}

output "bastion_public_ip" {
  description = "배스천 EC2 공인 IP — ssh -i <pem> ec2-user@<이 IP>"
  value       = aws_instance.terraform_pub_ec2_bastion_2a.public_ip
}

output "rds_endpoint" {
  description = "MariaDB 접속 엔드포인트"
  value       = aws_db_instance.terraform_mariadb_rds.endpoint
}
