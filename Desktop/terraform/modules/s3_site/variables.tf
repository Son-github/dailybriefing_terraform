variable "name" {
  description = "리소스 접두사 (예: dailybriefing-dev)"
  type        = string
}

variable "bucket_force_destroy" {
  description = "버킷 비우기/삭제 허용(개발용)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}
