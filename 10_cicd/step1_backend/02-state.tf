# ============================================================
# 02-state.tf — 모든 CI/CD의 기반이 되는 저장소 계층
#   tfstate 버킷 + DynamoDB lock + 파이프라인 artifact 버킷
#   → step2·step3가 outputs를 remote_state로 읽어간다
# ============================================================

# ---------- Terraform state backend (03_real이 사용) ----------
# S3 버킷 — state·artifact 저장소
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  # destroy 금지 장치: state가 들어있는 버킷은 실수로 지우면 안 됨
  lifecycle {
    prevent_destroy = true
  }
}

# 버저닝 — state 실수 덮어쓰기 복구용
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" } # state 이력 복구용
}

# SSE — 저장 데이터 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# 퍼블릭 차단 — state는 절대 공개 금지
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB lock — 동시 apply 방지 잠금 테이블
resource "aws_dynamodb_table" "tf_lock" {
  name         = "${var.project_name}-tf-lock"
  billing_mode = "PAY_PER_REQUEST" # state lock 전용 — 사용량 거의 없음
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ---------- 파이프라인 artifact 버킷 (step2·step3 공용) ----------
# S3 버킷 — state·artifact 저장소
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # 실습용 — 비우고 삭제 가능하게
}

# 퍼블릭 차단 — state는 절대 공개 금지
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
