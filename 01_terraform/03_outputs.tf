# ============================================================
# outputs.tf — apply 후 콘솔에 출력되는 값
# - terraform output 명령으로도 조회 가능
# - 출력이 다른 state의 입력이 되는 remote_state는 10_cicd에서 다룬다
# ============================================================

output "vpc_id" {
  value = aws_vpc.hello_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.hello_vpc.cidr_block
}
