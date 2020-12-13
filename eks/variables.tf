variable "aws_region" { }
variable "aws_profile" { }

variable "cluster_name" {
  default = "test"
  type    = string
}

variable "route53_zone_name" {
  default = "test"
  type    = string
}

