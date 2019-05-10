terraform {
  required_version = ">= 0.11.10"
}

provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region     = "${var.AWS_REGION}"
}

locals {
  domain_name = "${var.env}.${var.subdomain}"
}

# Request the creation of a certificate from AWS Certification Manager (ACM).
# https://www.terraform.io/docs/providers/aws/r/acm_certificate.html
resource "aws_acm_certificate" "cert" {
  domain_name       = "${local.domain_name}"
  validation_method = "DNS"

  tags = "${merge(var.default_tags, map(
    "Name", "cert-${var.env}"
  ))}"

  lifecycle {
    create_before_destroy = true
  }
}

# The hosted zone into which the Route 53 entry will be added.
data "aws_route53_zone" "zone" {
  name         = "${var.route53_zone}"
  private_zone = false
}

# This creates a record within Route 53 to confirm control of this domain.
# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.zone.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

# This resource does not create or destroy anything. This is part of the certificate validation
# workflow from the previous route53_record (cert_validation) and certificate request (cert) steps.
# This validates that the certificate generated for the load balancer matches the Route 53 entry
# that was added for it.
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]

  # Add a timeout so a dev isn't waiting for the default 45 minute timeout
  timeouts {
    create = "10m"
  }
}
