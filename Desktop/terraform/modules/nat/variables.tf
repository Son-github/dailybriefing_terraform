variable "name" {
  description = "리소스 이름 prefix"
  type        = string
}

variable "public_subnet_id" {
  description = "NAT을 배치할 퍼블릭 서브넷 ID"
  type        = string
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}
