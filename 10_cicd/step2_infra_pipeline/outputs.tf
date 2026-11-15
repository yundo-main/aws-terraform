# ============================================================
# outputs.tf — step3가 읽는 값 + 사용자에게 필요한 정보
# ============================================================

output "codebuild_role_arn" {
  description = "step3 앱 빌드·배포가 공용으로 쓰는 CodeBuild 역할"
  value       = aws_iam_role.codebuild.arn
}

output "pipeline_role_arn" {
  description = "step3 앱 파이프라인이 공용으로 쓰는 CodePipeline 역할"
  value       = aws_iam_role.pipeline.arn
}

output "repo_clone_http" {
  description = "인프라 리포 CodeCommit 클론 URL"
  value       = aws_codecommit_repository.src.clone_url_http
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
