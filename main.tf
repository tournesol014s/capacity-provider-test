terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.76.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      env = "capacity-provider-test"
    }
  }
}

data "aws_caller_identity" "self" {}

variable "region" {
  default = "ap-northeast-1"
}

variable "enable_private_subnet" {
  type    = bool
  default = true
}

variable "enable_multi_az_nat_gw" {
  type    = bool
  default = false
}