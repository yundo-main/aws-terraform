# ============================================================
# main.tf — 인프라 GitOps 파이프라인
#   .tf push → CodeBuild(plan) → 수동승인 → CodeBuild(apply)
#   artifact 버킷·저장소 리소스는 같은 디렉터리의 02-state.tf
# ============================================================

# ---------- 소스: GitHub (CodeConnections) ----------
# GitHub 연결 — apply 후 콘솔에서 PENDING → AVAILABLE 승인이 수동 1회 필요 (OAuth)
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github"
  provider_type = "GitHub"
}

# ---------- IAM: CodeBuild 역할 (11_gitops_app의 앱 빌드/배포도 공용) ----------
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
    { name = "TFSTATE_BUCKET", value = aws_s3_bucket.tfstate.bucket },
    { name = "TFSTATE_KEY", value = var.state_key },
    { name = "TFLOCK_TABLE", value = aws_dynamodb_table.tf_lock.name },
  ]
}

# CodeBuild — plan/apply 실행 환경
resource "aws_codebuild_project" "plan" {
  name         = "${var.project_name}-plan"
  service_role = aws_iam_role.codebuild.arn

  source {
    type      = "CODEPIPELINE" # 파이프라인이 소스를 전달
    buildspec = "10_gitops_infra/buildspec-plan.yml"
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
    buildspec = "10_gitops_infra/buildspec-apply.yml"
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

# ---------- IAM: CodePipeline 역할 (11_gitops_app 앱 파이프라인도 공용) ----------
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
    resources = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]
  }
  statement { # GitHub 연결 사용
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github.arn]
  }
  statement { # CodeBuild 실행·조회 — 인프라·앱 모든 프로젝트
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
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_out"]
      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = var.github_repo
        BranchName           = var.repo_branch
        OutputArtifactFormat = "CODE_ZIP"
        DetectChanges        = "true" # webhook — push 감지 자동 실행
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
