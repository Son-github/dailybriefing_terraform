locals {
  use_default_cert = var.certificate_arn == null || var.certificate_arn == ""
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.name}-oac"
  description                       = "OAC for ${var.name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  price_class         = var.price_class
  default_root_object = var.default_root_object
  web_acl_id          = var.enable_waf && var.web_acl_arn != null ? var.web_acl_arn : null

  # ✅ origin (단수) 블록을 사용
  origin {
    domain_name              = var.s3_bucket_domain_name
    origin_id                = "s3-${var.s3_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${var.s3_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    compress         = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  # SPA 라우팅
  custom_error_response {
    error_code            = 403
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
  }
  custom_error_response {
    error_code            = 404
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.use_default_cert
    acm_certificate_arn            = local.use_default_cert ? null : var.certificate_arn
    ssl_support_method             = local.use_default_cert ? null : "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = merge(var.tags, { Name = "${var.name}-cdn" })
}

# S3 버킷 정책: CloudFront(OAC)만 접근 가능
data "aws_iam_policy_document" "site" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = var.s3_bucket_id
  policy = data.aws_iam_policy_document.site.json
}
