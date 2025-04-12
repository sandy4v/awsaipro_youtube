# # Define the AWS Provider for CloudFront (usually the same as your main region)
# provider "aws" {
#   region = var.aws_region # The AWS region where your S3 bucket is located (e.g., us-east-2)
# }

# Create the CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = var.s3_bucket_domain_name # Use the input variable # The S3 bucket domain name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  enabled             = true # Enable the CloudFront distribution
  is_ipv6_enabled     = true # Enable IPv6 support
  default_root_object = "index.html" # The default file to serve at the root

  aliases = [var.domain_name] # The custom domain name(s) for the distribution

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"] # HTTP methods CloudFront will allow
    cached_methods   = ["GET", "HEAD"] # HTTP methods CloudFront will cache
    target_origin_id = "S3Origin" # Reference to the origin

    forwarded_values {
      query_string = false # Don't forward query strings to the origin
      cookies {
        forward = "none" # Don't forward cookies to the origin
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Redirect HTTP requests to HTTPS
    min_ttl                = 0 # Minimum time to live for cached objects
    default_ttl            = 3600 # Default time to live for cached objects (in seconds)
    max_ttl                = 86400 # Maximum time to live for cached objects
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # No geographical restrictions
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn # The ARN of the ACM certificate
    ssl_support_method    = "sni-only" # Use Server Name Indication (SNI) for SSL
    minimum_protocol_version = "TLSv1.2_2019" # Minimum TLS protocol version
  }
 
  tags = {
    Environment = "Production"
    Website     = var.domain_name # Tag the distribution with the domain name
  }
}

# Create a CloudFront Origin Access Identity (OAI) to restrict S3 bucket access
resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "OAI for ${var.domain_name}" # Comment for the OAI
}

output "cloudfront_domain" {
  description = "The CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name # The generated domain name of the CloudFront distribution
}