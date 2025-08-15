terraform {
  required_version = ">= 0.12.0, < 2.0.0" # 구버전도 통과하도록 완화
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0" # 0.12와 잘 맞는 안정 구간
    }
  }
}
