# 기본 provider(ap-northeast-2)와 us-east-1(alias=use1) 둘 다 필요
data "aws_route53_zone" "primary" {
  name         = var.root_domain
  private_zone = false
}

# ---------- ACM (CloudFront용 / us-east-1) ----------
resource "aws_acm_certificate" "frontend" {
  count                = var.create_frontend_cert ? 1 : 0
  provider             = aws.use1
  domain_name          = var.root_domain
  validation_method    = "DNS"
  subject_alternative_names = var.include_www ? ["www.${var.root_domain}"] : []
}

resource "aws_route53_record" "frontend_validations" {
  count   = var.create_frontend_cert ? length(aws_acm_certificate.frontend[0].domain_validation_options) : 0
  zone_id = data.aws_route53_zone.primary.zone_id

  name    = aws_acm_certificate.frontend[0].domain_validation_options[count.index].resource_record_name
  type    = aws_acm_certificate.frontend[0].domain_validation_options[count.index].resource_record_type
  ttl     = 60
  records = [aws_acm_certificate.frontend[0].domain_validation_options[count.index].resource_record_value]
}

resource "aws_acm_certificate_validation" "frontend" {
  count                  = var.create_frontend_cert ? 1 : 0
  provider               = aws.use1
  certificate_arn        = aws_acm_certificate.frontend[0].arn
  validation_record_fqdns = [for r in aws_route53_record.frontend_validations : r.fqdn]
}

# ---------- ACM (API용 / ap-northeast-2) ----------
resource "aws_acm_certificate" "api" {
  count             = var.create_api_cert ? 1 : 0
  domain_name       = "api.${var.root_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "api_validation" {
  count   = var.create_api_cert ? length(aws_acm_certificate.api[0].domain_validation_options) : 0
  zone_id = data.aws_route53_zone.primary.zone_id

  name    = aws_acm_certificate.api[0].domain_validation_options[count.index].resource_record_name
  type    = aws_acm_certificate.api[0].domain_validation_options[count.index].resource_record_type
  ttl     = 60
  records = [aws_acm_certificate.api[0].domain_validation_options[count.index].resource_record_value]
}

resource "aws_acm_certificate_validation" "api" {
  count                   = var.create_api_cert ? 1 : 0
  certificate_arn         = aws_acm_certificate.api[0].arn
  validation_record_fqdns = [for r in aws_route53_record.api_validation : r.fqdn]
}

# ---------- Route53 레코드 ----------
# root → CloudFront
resource "aws_route53_record" "root_a" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.root_domain
  type    = "A"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_aaaa" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.root_domain
  type    = "AAAA"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

# (선택) www → CloudFront (SAN 포함시)
resource "aws_route53_record" "www_a" {
  count  = var.include_www ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "www.${var.root_domain}"
  type    = "A"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "www_aaaa" {
  count  = var.include_www ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "www.${var.root_domain}"
  type    = "AAAA"
  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}

# api → ALB
resource "aws_route53_record" "api_a" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "api.${var.root_domain}"
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_aaaa" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "api.${var.root_domain}"
  type    = "AAAA"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

