terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.15.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
}


