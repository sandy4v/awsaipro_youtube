#root variables.tf
variable "domain_name" {
  description = "The domain name for the website and certificate"
  type        = string
  default     = "techwithsandy.click" # Set default based on context
}

variable "aws_region" {
  description = "The primary AWS region for resources (e.g., S3 bucket)"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
  default     = "sandy4v"
}

#===Step2 Commented===
variable "zone_id" {
  description = "The Route 53 hosted zone ID where validation records will be created"
  type        = string
  # You'll need to replace this with your actual hosted zone ID once hosted zone is created
  default     = ""
}
#===Step2 Commented===

# #===Step1 Commented===
# variable "zone_id" {
#   description = "The Route 53 hosted zone ID where validation records will be created"
#   type        = string
#   # You'll need to replace this with your actual hosted zone ID once hosted zone is created
#   default     = "Z0151931NHBLUCA1RYFN"
# }
# #===Step1 Commented===