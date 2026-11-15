# ============================================================
# main.tf — 03_real 위에 HTTPS를 얹는 선택 단계
# 03이 만든 ALB·Route53 존을 terraform_remote_state로 읽어
# 인증서 발급 → 443 규칙 → HTTPS 리스너만 추가한다
# ============================================================

# remote_state — 03_real의 outputs를 읽는 data 소스
# 별도 state라 직접 참조(aws_lb.app.arn)가 불가 → outputs 경유
# 03_real이 apply 되어 있지 않으면 plan 단계에서 실패
data "terraform_remote_state" "real" {
  backend = "local"
  config = {
    path = var.real_state_path
  }
}

locals {
  # 03의 outputs를 짧은 이름으로 — 읽는 쪽 코드가 깔끔해짐
  real = data.terraform_remote_state.real.outputs

  # 도메인과 존이 둘 다 있어야 이 단계의 리소스가 의미가 있음
  # 비어 있으면 전부 count=0 — plan은 되지만 아무것도 안 만듦
  domain_enabled = var.domain_name != "" && local.real.route53_zone_id != ""
}


# ---------------- ACM 인증서 ----------------
# DNS 검증 — Route53에 검증 레코드를 자동 생성해 콘솔 작업 불필요

# ACM 인증서 — TLS 발급 (DNS 검증)
resource "aws_acm_certificate" "app" {
  count             = local.domain_enabled ? 1 : 0
  domain_name       = "app.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true # 재발급 시 새 인증서를 먼저 만들고 교체
  }
}

# 검증용 DNS 레코드 — 03의 Route53 존에 생성
resource "aws_route53_record" "cert_validation" {
  for_each = local.domain_enabled ? {
    for o in aws_acm_certificate.app[0].domain_validation_options : o.domain_name => o
  } : {}

  zone_id = local.real.route53_zone_id # 03의 존 — remote_state 출력 참조
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

# 검증 대기 — 레코드 전파까지 apply가 블로킹 (수 분 소요 가능)
resource "aws_acm_certificate_validation" "app" {
  count                   = local.domain_enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}


# ---------------- ALB에 443 연결 ----------------
# 03의 리소스를 수정하는 것이 아니라 "규칙·리스너"를 새 리소스로 부착
# → 03의 state를 건드리지 않고 확장하는 패턴

# SG 규칙 — 03의 ALB SG에 443 인바운드 추가
resource "aws_security_group_rule" "alb_https" {
  count             = local.domain_enabled ? 1 : 0
  type              = "ingress"
  security_group_id = local.real.alb_sg_id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS"
}

# HTTPS 리스너 — 03의 ALB에 부착, 03의 타깃그룹으로 전달
resource "aws_lb_listener" "https" {
  count             = local.domain_enabled ? 1 : 0
  load_balancer_arn = local.real.alb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = local.real.alb_target_group_arn
  }
}
