#root main.tf
# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
}

# Reference the existing S3 bucket
data "aws_s3_bucket" "website_bucket" {
  bucket = var.domain_name
}

# Configure website hosting on the S3 bucket
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = data.aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Block all public access settings need to be configured for the existing bucket.
# Ensure these settings allow public access if needed for the website.
# This resource block assumes you want Terraform to manage these settings.
# If the existing bucket already has the correct public access settings,
# you might consider removing this block or importing its state.
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = data.aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# Create the bucket policy document
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.website_bucket.arn}/*"] # Allow read access to all objects in the bucket
  }
}

# Apply the bucket policy to the S3 bucket
resource "aws_s3_bucket_policy" "bucket_policy_resource" {
  bucket = data.aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json

  # Ensure the public access block is configured before applying the policy
  depends_on = [aws_s3_bucket_public_access_block.block_public_access]
}

# Upload the index.html file to the S3 bucket
resource "aws_s3_object" "index_html" {
  bucket       = data.aws_s3_bucket.website_bucket.id
  key          = "index.html"
  content      = <<-EOF
    <!DOCTYPE html>
    <html>
    <head>
      <title>My Static Website</title>
    </head>
    <body>
      <h1>Welcome to your own website hosted on S3</h1>
      <img src="bedrock.jpg" alt="Bedrock Face">
    </body>
    </html>
  EOF
  content_type = "text/html"
}

# Upload the error.html file to the S3 bucket
resource "aws_s3_object" "error_html" {
  bucket       = data.aws_s3_bucket.website_bucket.id
  key          = "error.html"
  content      = <<-EOF
    <!DOCTYPE html>
    <html>
    <head>
      <title>Error</title>
    </head>
    <body>
      <h1>404 Error - Page Not Found</h1>
    </body>
    </html>
  EOF
  content_type = "text/html"
}

# Upload the bedrock.jpg file to the s3 bucket.
resource "aws_s3_object" "bedrock_jpg" {
  bucket       = data.aws_s3_bucket.website_bucket.id
  key          = "bedrock.jpg"
  source       = "bedrock.jpg" # Ensure bedrock.jpg is in the same directory as this Terraform file.
  content_type = "image/jpg"
}

# Call the Route 53 hosted zone module
module "route53_zone" {
  source = "./hosted-zone"
  domain_name = var.domain_name  # Pass the domain_name variable

  #===Step1 Commented - Start===
  cloudfront_domain_name = module.cloudfront.cloudfront_domain
  #===Step1 Commented - end===

}
#===Step1 Commented - Start===

# Call the ACM certificate module

module "acm_certificate" {
  source = "./acm"
  providers = {
    aws = aws.us_east_1
  }
  domain_name = var.domain_name
  zone_id     = module.route53_zone.route53_zone_id # Use the output from the hosted zone module
}

# Call the CloudFront module
module "cloudfront" {
  source = "./cloudfront"
 
 providers = {
    aws = aws.us_east_1
  }

  aws_region              = var.aws_region
  domain_name             = var.domain_name
  s3_bucket_domain_name   = data.aws_s3_bucket.website_bucket.bucket_domain_name
  acm_certificate_arn     = module.acm_certificate.certificate_arn
  depends_on = [ module.acm_certificate ]

}
#===Step1 Commented - End===

output "website_url_http" {
  value       = "http://${aws_s3_bucket_website_configuration.website_config.website_endpoint}"
  description = "The HTTP URL of the static website"
}

output "website_url_https" {
  value       = "https://${var.domain_name}"
  description = "The HTTPS URL of the static website"
}

output "hosted_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = module.route53_zone.route53_zone_id
}

output "route53_name_servers" {
  description = "Name servers for the hosted zone created by the module"
  value       = module.route53_zone.route53_name_servers
}
