provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project
      Env     = var.env
    }
  }
}

data "aws_region" "current" {}

