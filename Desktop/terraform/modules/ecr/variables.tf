variable "project" {
  description = "프로젝트 접두사 (최종 리포: <project>/<service>)"
  type        = string
}

variable "repositories" {
  description = "생성할 ECR 리포 목록"
  type        = list(string)
}

variable "untagged_expire_days" {
  type    = number
  default = 7
}

variable "keep_last_images" {
  type    = number
  default = 20
}

variable "force_delete" {
  type    = bool
  default = false
}

variable "enable_github_oidc" {
  type    = bool
  default = true
}

variable "existing_oidc_provider_arn" {
  description = "이미 계정에 GitHub OIDC Provider가 있을 경우 그 ARN"
  type        = string
  default     = null
}

variable "oidc_thumbprints" {
  description = "GitHub OIDC thumbprint"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "github_org" {
  type    = string
  default = ""
}

variable "github_repo" {
  type    = string
  default = ""
}

variable "allowed_branches" {
  type    = list(string)
  default = ["main"]
}

variable "github_role_name" {
  type    = string
  default = "gha-ecr-push"
}

variable "tags" {
  type    = map(string)
  default = {}
}
