variable "aws_region" {
  description = "The AWS region where your S3 bucket is located (e.g., us-east-2)"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the website (e.g., techwithsandy.click)"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "The S3 bucket domain name (e.g., techwithsandy.click.s3.amazonaws.com)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  type        = string
}