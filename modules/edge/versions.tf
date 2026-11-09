terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # The WAFv2 Web ACL for CloudFront must live in us-east-1.
      configuration_aliases = [aws.us_east_1]
    }
  }
}
