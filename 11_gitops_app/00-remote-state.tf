# ============================================================
# 00-remote-state.tf — 10_gitops_infra의 출력을 읽는 연결부
#   artifact 버킷·공용 역할·connection을 한 state에서 가져온다
# ============================================================

# remote_state — 다른 단계의 출력 읽기
data "terraform_remote_state" "cicd" {
  backend = "local"
  config = {
    path = "../10_gitops_infra/terraform.tfstate"
  }
}

locals {
  artifacts_bucket   = data.terraform_remote_state.cicd.outputs.artifacts_bucket
  codebuild_role_arn = data.terraform_remote_state.cicd.outputs.codebuild_role_arn
  pipeline_role_arn  = data.terraform_remote_state.cicd.outputs.pipeline_role_arn
  pipeline_role_name = data.terraform_remote_state.cicd.outputs.pipeline_role_name
  connection_arn     = data.terraform_remote_state.cicd.outputs.github_connection_arn
}
