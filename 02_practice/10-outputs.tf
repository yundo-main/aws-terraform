# ============================================================
# outputs.tf — apply 후 확인할 값 (계층별로 묶어둠)
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
