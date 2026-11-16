# ============================================================
# outputs.tf — 11_infra_pipeline·12_app_pipeline이 remote_state로 읽는 값
# ============================================================

output "artifacts_bucket" {
  description = "파이프라인 artifact 저장 버킷"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "파이프라인 IAM 정책에 쓸 artifact 버킷 ARN"
  value       = aws_s3_bucket.artifacts.arn
}

output "tfstate_bucket" {
  description = "Terraform state 저장 버킷 (backend 설정용)"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tf_lock_table" {
  description = "state 잠금 DynamoDB 테이블"
  value       = aws_dynamodb_table.tf_lock.name
}
