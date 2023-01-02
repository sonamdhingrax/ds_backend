# Creates the Certificate in ACM required to host api.simplifycloud.uk and staging-api.simplifycloud.uk
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.simplifycloud.uk",
    "simplifycloud.uk",
  ]
}

# Gets the data from route53 for the hosted zone simplifycloud.uk created outside this terraform config
data "aws_route53_zone" "domain_name" {
  name = var.domain_name
}

# Adds record for validating that we can control the domain name for which we are generating SSL Certs in ACM
resource "aws_route53_record" "validate_acm_cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain_name.zone_id
}
