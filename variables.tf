variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key"
}

variable "AWS_REGION" {
  description = "AWS Region"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Key"
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = "map"
}

variable "env" {
  description = "The env to be combined with the subdomain to create a Route53 entry + ACM Certificate"
}

variable "route53_zone" {
  description = "The route53 zone to use"
}

variable "subdomain" {
  description = "The subdomain to be combined with the env to create a Route53 entry + ACM Certificate"
}
