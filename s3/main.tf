terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-southeast-1"
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  # insert the 5 required variables here

  bucket = "clusters.dev.aushafy.my.id"
  acl    = "private"
  
  versioning = {
    enabled = false
  }
}