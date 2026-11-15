# ============================================================
# main.tf — 인프라 GitOps 파이프라인
#   .tf push → CodeBuild(plan) → 수동승인 → CodeBuild(apply)
#   artifact 버킷은 step1 remote_state로 참조
# ============================================================

# ---------- 소스: CodeCommit ----------
# CodeCommit — git 리포 (push = 파이프라인 트리거)
resource "aws_codecommit_repository" "src" {
  repository_name = var.repo_name
  description     = "Terraform CI/CD 실습 리포 — push하면 파이프라인 자동 실행"
}

# ---------- IAM: CodeBuild 역할 (step3의 앱 빌드/배포도 공용) ----------
# 정책 문서 — 역할 신뢰·권한 JSON 생성
data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

# IAM 역할 — 파이프라인·빌드 실행 주체
resource "aws_iam_role" "codebuild" {
  name               = "${var.project_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

# 학습용 — terraform이 모든 리소스를 만들 수 있어야 하므로 관리형 정책 부여
# 실무에서는 필요한 서비스만 추린 최소권한 정책을 작성한다
# 역할↔관리형 정책 부착
resource "aws_iam_role_policy_attachment" "codebuild_admin" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---------- CodeBuild 프로젝트 ×2 ----------
locals {
  build_env = [
    { name = "TF_VERSION", value = var.tf_version },
    { name = "TF_DIR", value = var.tf_dir },
    { name = "TFSTATE_BUCKET", value = local.tfstate_bucket },
    { name = "TFSTATE_KEY", value = var.state_key },
    { name = "TFLOCK_TABLE", value = local.tf_lock_table },
  ]
}

# CodeBuild — plan/apply 실행 환경
resource "aws_codebuild_project" "plan" {
  name         = "${var.project_name}-plan"
  service_role = aws_iam_role.codebuild.arn

  source {
    type      = "CODEPIPELINE" # 파이프라인이 소스를 전달
    buildspec = "10_cicd/step2_infra_pipeline/buildspec-plan.yml"
  }
  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    dynamic "environment_variable" {
      for_each = local.build_env
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }
}

# CodeBuild — plan/apply 실행 환경
resource "aws_codebuild_project" "apply" {
  name         = "${var.project_name}-apply"
  service_role = aws_iam_role.codebuild.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = "10_cicd/step2_infra_pipeline/buildspec-apply.yml"
  }
  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    dynamic "environment_variable" {
      for_each = local.build_env
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }
}

# ---------- IAM: CodePipeline 역할 (step3 앱 파이프라인도 공용) ----------
# 정책 문서 — 역할 신뢰·권한 JSON 생성
data "aws_iam_policy_document" "pipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

# IAM 역할 — 파이프라인·빌드 실행 주체
resource "aws_iam_role" "pipeline" {
  name               = "${var.project_name}-pipeline"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume.json
}

# 정책 문서 — 역할 신뢰·권한 JSON 생성
data "aws_iam_policy_document" "pipeline" {
  statement { # artifact 버킷 읽기/쓰기
    actions   = ["s3:Get*", "s3:Put*", "s3:ListBucket"]
    resources = [local.artifacts_bucket_arn, "${local.artifacts_bucket_arn}/*"]
  }
  statement { # CodeCommit 소스 읽기 — 두 리포 모두 허용
    actions = ["codecommit:GetBranch", "codecommit:GetCommit", "codecommit:GetRepository",
    "codecommit:UploadArchive", "codecommit:GetUploadArchiveStatus", "codecommit:CancelUploadArchive"]
    resources = [aws_codecommit_repository.src.arn]
  }
  statement { # CodeBuild 실행·조회 — step2·step3 모든 프로젝트
    actions   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds", "codebuild:StopBuild"]
    resources = ["arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.project_name}-*"]
  }
}

# 인라인 정책 — 역할의 구체 권한
resource "aws_iam_role_policy" "pipeline" {
  name   = "${var.project_name}-pipeline"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline.json
}

# ---------- CodePipeline ----------
# CodePipeline — 단계 오케스트레이션
resource "aws_codepipeline" "tf" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = local.artifacts_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_out"]
      configuration = {
        RepositoryName       = aws_codecommit_repository.src.repository_name
        BranchName           = var.repo_branch
        PollForSourceChanges = "false" # EventBridge 규칙이 자동 생성돼 push 감지
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name             = "TerraformPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_out"]
      output_artifacts = ["plan_out"] # tfplan 파일을 다음 단계로 전달
      configuration = {
        ProjectName = aws_codebuild_project.plan.name
      }
    }
  }

  stage {
    name = "Approve"
    action {
      name      = "ManualApproval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 1
      # 콘솔에서 plan 로그 확인 후 승인 버튼
      configuration = {
        CustomData = "Plan 로그를 확인한 뒤 승인하세요"
      }
    }
  }

  stage {
    name = "Apply"
    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["plan_out"] # plan 결과물 그대로 적용
      configuration = {
        ProjectName = aws_codebuild_project.apply.name
      }
    }
  }
}
