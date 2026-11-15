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

output "eks_cluster_name" {
  description = "EKS 클러스터 이름 — aws eks update-kubeconfig 대상"
  value       = aws_eks_cluster.terraform_eks_cluster.name
}

output "ecr_repository_url" {
  description = "앱 이미지 푸시 대상 ECR"
  value       = aws_ecr_repository.terraform_ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS — 도메인 없으면 이 주소로 접속"
  value       = aws_lb.app.dns_name
}

output "route53_name_servers" {
  description = "도메인 등록기관에 설정할 NS — 위임해야 app.<도메인>이 동작"
  value       = local.domain_enabled ? aws_route53_zone.route53[0].name_servers : []
}

output "app_url" {
  description = "앱 접속 주소"
  value       = local.domain_enabled ? "http://app.${var.domain_name}" : "http://${aws_lb.app.dns_name}"
}

# ---- 04_https가 remote_state로 읽는 값 ----

output "alb_arn" {
  description = "ALB ARN — 04_https의 리스너 부착 대상"
  value       = aws_lb.app.arn
}

output "alb_sg_id" {
  description = "ALB 보안 그룹 ID — 04_https가 443 규칙을 추가"
  value       = aws_security_group.terraform_sg_alb.id
}

output "alb_target_group_arn" {
  description = "ALB 타깃그룹 ARN — 04_https 리스너의 forward 대상"
  value       = aws_lb_target_group.app.arn
}

output "route53_zone_id" {
  description = "호스팅 존 ID — 04_https의 ACM 검증 레코드 생성 위치 (도메인 없으면 빈 문자열)"
  value       = local.domain_enabled ? aws_route53_zone.route53[0].zone_id : ""
}
