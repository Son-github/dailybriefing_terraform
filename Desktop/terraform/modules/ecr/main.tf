locals {
  repo_names = [for r in var.repositories : "${var.project}/${r}"]

  allowed_subjects = [
    for b in var.allowed_branches :
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${b}"
  ]
}

# --- ECR repositories ---
resource "aws_ecr_repository" "this" {
  for_each             = toset(local.repo_names)
  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS" # 커스텀 KMS 키 미지정 → alias/aws/ecr 사용
  }

  tags = merge(var.tags, {
    Module  = "ecr"
    Service = split("/", each.value)[1]
  })
}

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than ${var.untagged_expire_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countNumber = var.untagged_expire_days
          countUnit   = "days"
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only last ${var.keep_last_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_last_images
        }
        action = { type = "expire" }
      }
    ]
  })
}

# --- GitHub OIDC Provider (옵션) ---
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.enable_github_oidc && var.existing_oidc_provider_arn == null ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.oidc_thumbprints
}

# OIDC Provider ARN 안전 결정: 기존 값 우선 → 새로 만든 리소스 → null
locals {
  oidc_provider_arn = coalesce(
    var.existing_oidc_provider_arn,
    try(aws_iam_openid_connect_provider.github[0].arn, null)
  )
}

# AssumeRole 정책 (조건 충족 시 생성)
data "aws_iam_policy_document" "github_assume" {
  count = var.enable_github_oidc && local.oidc_provider_arn != null && var.github_org != "" && var.github_repo != "" ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "gha_ecr_push" {
  count              = length(data.aws_iam_policy_document.github_assume) > 0 ? 1 : 0
  name               = var.github_role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecr_push" {
  count = length(aws_iam_role.gha_ecr_push) > 0 ? 1 : 0

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecr_push_attach" {
  count  = length(aws_iam_role.gha_ecr_push) > 0 ? 1 : 0
  role   = aws_iam_role.gha_ecr_push[0].id
  policy = data.aws_iam_policy_document.ecr_push[0].json
}
