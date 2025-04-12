#hosted zone main.tf
# Create a public hosted zone for the domain
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

##===Step1 Commented - Start===
# Create an A record pointing to the CloudFront distribution
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # Hosted Zone ID for CloudFront
    evaluate_target_health = false
  }
}
##===Step1 Commented - End===

output "route53_zone_id" {
  description = "The ID of the created Route 53 hosted zone"
  value       = aws_route53_zone.primary.id
}

output "route53_name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.primary.name_servers
}