# ============================================================
# outputs — 다음 단계(step2, step3)에서 remote_state로 참조한다
# ============================================================

output "vpc_id" {
  value = aws_vpc.terraform_vpc.id
}

output "pub_subnet_2a_id" {
  value = aws_subnet.terraform_pub_subnet_2a.id
}

output "pub_subnet_2c_id" {
  value = aws_subnet.terraform_pub_subnet_2c.id
}

output "pri_subnet_2a_id" {
  value = aws_subnet.terraform_pri_subnet_2a.id
}

output "pri_subnet_2c_id" {
  value = aws_subnet.terraform_pri_subnet_2c.id
}
