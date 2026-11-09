# WAFv2 Web ACL for CloudFront. Scope CLOUDFRONT resources must be
# created in us-east-1 (hence the aliased provider).
resource "aws_wafv2_web_acl" "this" {
  provider = aws.us_east_1

  name  = "${var.project}-${var.environment}-api-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-api-waf-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-managed-common"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-api-waf-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-api-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-api-waf"
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project}-${var.environment} API (ALB origin)"
  price_class         = var.price_class
  web_acl_id          = aws_wafv2_web_acl.this.arn
  aliases             = var.acm_certificate_arn_us_east_1 != "" ? [var.api_domain] : []
  retain_on_delete    = false
  wait_for_deployment = false

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default: the API is not cached (pass-through). All methods, all
  # cookies, and the auth/host headers are forwarded so the API sees
  # the request as the client sent it.
  default_cache_behavior {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }

      headers = ["Authorization", "Host", "Origin", "Referer", "Accept", "Accept-Language", "Content-Type"]
    }
  }

  # Queue frontier (ADR-0015): a 1-second edge cache absorbs the
  # waiting-room polling load. No Authorization header is forwarded,
  # so the cached response is shared by all users of an event —
  # this assumes the frontier endpoint is public (no per-user auth).
  # If the queue app requires auth on the frontier, forward
  # Authorization here (cache sharing is lost) or make it public.
  ordered_cache_behavior {
    path_pattern           = "/v1/queue/*/frontier"
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    min_ttl                = 1
    default_ttl            = 1
    max_ttl                = 1

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }

      headers = ["Origin"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn_us_east_1 != "" ? [1] : []

    content {
      acm_certificate_arn      = var.acm_certificate_arn_us_east_1
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn_us_east_1 != "" ? [] : [1]

    content {
      cloudfront_default_certificate = true
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-api-cdn"
  }
}
