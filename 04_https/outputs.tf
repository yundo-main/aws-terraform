# ============================================================
# outputs.tf — apply 후 확인할 값
# ============================================================

output "certificate_arn" {
  description = "발급된 ACM 인증서 ARN"
  value       = local.domain_enabled ? aws_acm_certificate.app[0].arn : ""
}

output "https_url" {
  description = "HTTPS 접속 주소 — 인증서 검증·존 위임이 끝나야 열림"
  value       = local.domain_enabled ? "https://app.${var.domain_name}" : ""
}
