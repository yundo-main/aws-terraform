# ============================================================
# 00-remote-state.tf — 10_backend·11_infra_pipeline의 출력을 읽는 연결부
#   10_backend: artifact 버킷
#   11_infra_pipeline: 공용 CodeBuild·CodePipeline 역할
# ============================================================

# remote_state — 다른 step의 출력 읽기
data "terraform_remote_state" "backend" {
  backend = "local"
  config = {
    path = "../10_backend/terraform.tfstate"
  }
}

# remote_state — 다른 step의 출력 읽기
data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../11_infra_pipeline/terraform.tfstate"
  }
}

locals {
  artifacts_bucket   = data.terraform_remote_state.backend.outputs.artifacts_bucket
  codebuild_role_arn = data.terraform_remote_state.infra.outputs.codebuild_role_arn
  pipeline_role_arn  = data.terraform_remote_state.infra.outputs.pipeline_role_arn
  pipeline_role_name = data.terraform_remote_state.infra.outputs.pipeline_role_name
  connection_arn     = data.terraform_remote_state.infra.outputs.github_connection_arn
}
