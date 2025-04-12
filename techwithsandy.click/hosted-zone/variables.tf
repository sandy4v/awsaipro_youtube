#hosted zone variables.tf
variable "domain_name" {
  description = "The domain name"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  type        = string
  default     = ""
}