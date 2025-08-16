terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
  }

  # (옵션) backend "s3" {
  #   bucket         = "your-tf-state-bucket"
  #   key            = "dailybriefing/dev/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   encrypt        = true
  #   dynamodb_table = "tf-lock"
  # }
}
