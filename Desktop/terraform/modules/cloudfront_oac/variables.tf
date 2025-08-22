variable "name" {
  type        = string
  description = "리소스 접두사"
}

variable "s3_bucket_id" {
  type        = string
  description = "원본 S3 버킷 ID"
}

variable "s3_bucket_arn" {
  type        = string
  description = "원본 S3 버킷 ARN"
}

# ✅ S3 원본 도메인명 전달(권장: bucket_regional_domain_name)
variable "s3_bucket_domain_name" {
  type        = string
  description = "ex) my-bucket.s3.ap-northeast-2.amazonaws.com"
}

variable "default_root_object" {
  type        = string
  default     = "index.html"
}

variable "price_class" {
  type        = string
  default     = "PriceClass_200"
}

variable "certificate_arn" {
  description = "us-east-1의 CloudFront용 인증서 ARN (없으면 기본 인증서)"
  type        = string
  default     = null
}

variable "enable_waf" {
  type    = bool
  default = false
}

variable "web_acl_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
