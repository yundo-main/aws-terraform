output "app_repo_clone_http" {
  description = "앱 소스 CodeCommit 클론 URL"
  value       = aws_codecommit_repository.app.clone_url_http
}

output "app_ecr_url" {
  description = "앱 이미지 ECR 리포지토리 URL"
  value       = aws_ecr_repository.app.repository_url
}

output "app_pipeline_name" {
  description = "앱 배포 CodePipeline 이름"
  value       = aws_codepipeline.app.name
}
