# ============================================================
# main.tf — 애플리케이션 배포 파이프라인
#   앱 코드 push → docker build → ECR push → EKS 배포
#   소스 = GitHub dev 브랜치 (10_cicd의 connection 공용) — 역할·버킷도 remote_state로
# ============================================================

# ---------- 이미지 저장소 ----------
# ECR — 앱 이미지 저장소
resource "aws_ecr_repository" "app" {
  name         = var.app_name
  force_delete = true # 실습용 — 이미지 있어도 삭제 가능
}

# ---------- CodeBuild: docker build ----------
# CodeBuild — plan/apply 실행 환경
resource "aws_codebuild_project" "app_build" {
  name         = "${var.project_name}-app-build"
  service_role = local.codebuild_role_arn # 10_cicd의 공용 역할

  source {
    type      = "CODEPIPELINE"
    buildspec = "11_app_pipeline/buildspec-app-build.yml"
  }
  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # docker 데몬 사용에 필수

    environment_variable {
      name  = "ECR_URI"
      value = aws_ecr_repository.app.repository_url
    }
    environment_variable {
      name  = "APP_DIR"
      value = "11_app_pipeline/app"
    }
  }
}

# ---------- CodeBuild: EKS deploy ----------
# CodeBuild — plan/apply 실행 환경
resource "aws_codebuild_project" "app_deploy" {
  name         = "${var.project_name}-app-deploy"
  service_role = local.codebuild_role_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = "11_app_pipeline/buildspec-app-deploy.yml"
  }
  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = var.eks_cluster_name
    }
    environment_variable {
      name  = "APP_NAME"
      value = var.app_name
    }
  }
}

# ---------- CodePipeline: 앱 배포 ----------
# CodePipeline — 단계 오케스트레이션
resource "aws_codepipeline" "app" {
  name     = "${var.project_name}-app-pipeline"
  role_arn = local.pipeline_role_arn # 10_cicd의 공용 역할

  artifact_store {
    location = local.artifacts_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "AppSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["app_source"]
      configuration = {
        ConnectionArn        = local.connection_arn
        FullRepositoryId     = var.github_repo
        BranchName           = var.repo_branch
        OutputArtifactFormat = "CODE_ZIP"
        DetectChanges        = "true"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "DockerBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["app_source"]
      output_artifacts = ["image_out"] # imageDetail.json — 다음 단계가 읽을 이미지 태그
      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployEKS"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["image_out"]
      configuration = {
        ProjectName = aws_codebuild_project.app_deploy.name
      }
    }
  }
}
