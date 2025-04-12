variable "domain_name" {
  description = "The domain name for the certificate (e.g., techwithsandy.click)"
  type        = string
}

variable "zone_id" {
  description = "The Route 53 hosted zone ID where validation records will be created"
  type        = string
}