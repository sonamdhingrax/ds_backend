# The region from where the lambda, API gateway and ACM certs will be created in
variable "region" {
  default = "eu-west-2"
}

# The account to which the backend is deployed to
variable "account_id" {
  default = "406883836544"
}

# Name of the backend-application goes here
variable "app_name" {
  default = "timeInformation"
}

# The domain stated here should have already been confgured in Route53
variable "domain_name" {
  default = "simplifycloud.uk"
}
