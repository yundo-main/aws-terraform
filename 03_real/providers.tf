provider "aws" {
  region = var.aws_region # Asia Pacific (Seoul)

  default_tags {
    tags = {
      Project = var.project_name
      Managed = "terraform"
    }
  }
}
