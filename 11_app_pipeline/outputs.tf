output "app_ecr_url" {
  description = "앱 이미지 ECR 리포지토리 URL"
  value       = aws_ecr_repository.app.repository_url
}

output "app_pipeline_name" {
  description = "앱 배포 CodePipeline 이름"
  value       = aws_codepipeline.app.name
}
