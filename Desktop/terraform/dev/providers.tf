provider "aws" {
  region = var.region
}

# CloudFront 커스텀 도메인용 us-east-1 인증서가 필요할 때 사용
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
