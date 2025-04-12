# Request the ACM certificate in us-east-1
# The provider configuration is inherited from the root module call
#ACM cert will wait for validation - DNS / EMail validation 
# DNS validation is default and preferred 

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name # The domain name for the certificate (passed as a variable)
  validation_method = "DNS" # Use DNS validation for the certificate
  #validation_method = "EMAIL" # Use EMAIL validation for the certificate

  lifecycle {
    create_before_destroy = true # Create a new certificate before destroying the old one
  }

  tags = {
    Name = "${var.domain_name}-certificate" # Tag the certificate with the domain name
  }
}

# Comment for EMAIL Validation / Uncomment for DNS Validation
# Create the DNS validation record(s) in the specified Route 53 zone
# This uses the default provider (inherited from root, e.g., us-east-2)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name # The name of the DNS record to create
      record = dvo.resource_record_value # The value of the DNS record
      type   = dvo.resource_record_type # The type of the DNS record (CNAME)
    }
  }

  allow_overwrite = true # Allow overwriting existing records if they match
  name            = each.value.name # Set the name of the DNS record
  records         = [each.value.record] # Set the value of the DNS record (as a list)
  ttl             = 60 # Set the Time-to-Live for the DNS record in seconds
  type            = each.value.type # Set the type of the DNS record
  zone_id         = var.zone_id # The ID of the Route 53 hosted zone (passed as a variable)
}

# Validate the ACM certificate using the DNS records (waits for propagation)
# The provider configuration is inherited from the root module call
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn # The ARN of the ACM certificate to validate
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn] # List of FQDNs of the DNS validation records
}

output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}
