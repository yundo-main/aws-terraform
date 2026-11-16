# ============================================================
# outputs.tf — 12_app_pipeline이 읽는 값 + 사용자에게 필요한 정보
# ============================================================

output "codebuild_role_arn" {
  description = "12_app_pipeline 앱 빌드·배포가 공용으로 쓰는 CodeBuild 역할"
  value       = aws_iam_role.codebuild.arn
}

output "pipeline_role_arn" {
  description = "12_app_pipeline 앱 파이프라인이 공용으로 쓰는 CodePipeline 역할"
  value       = aws_iam_role.pipeline.arn
}

output "pipeline_role_name" {
  description = "같은 역할의 이름 — 11이 소스 리포 권한 정책을 부착할 때 사용"
  value       = aws_iam_role.pipeline.name
}

output "github_connection_arn" {
  description = "GitHub 연결 ARN — 콘솔에서 AVAILABLE 승인 후 파이프라인 동작"
  value       = aws_codestarconnections_connection.github.arn
}

output "pipeline_name" {
  description = "인프라 CodePipeline 이름"
  value       = aws_codepipeline.tf.name
}

output "backend_snippet" {
  description = "03_real/versions.tf에 붙여넣을 backend 설정"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${local.tfstate_bucket}"
      key            = "${var.state_key}"
      region         = "${var.aws_region}"
      dynamodb_table = "${local.tf_lock_table}"
    }
  EOT
}
