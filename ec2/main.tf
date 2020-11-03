terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

data "aws_vpc" "default" {
    default = true
}

data "aws_security_group" "aushafy-sg" {
  vpc_id = data.aws_vpc.default.id
  name   = "aushafy-sg"
}

data "aws_subnet" "default" {
  vpc_id     = data.aws_vpc.default.id
  availability_zone = "ap-southeast-1a"
}

locals {
    user_data = <<EOF
        #!/bin/bash
        echo "Hello Terraform!"
        sudo apt-get update -y && apt-get install python -y 
    EOF
}

module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.15.0"
  # insert the 10 required variables here
  
  instance_count                    = 1
  ami                               = "ami-0c8e97a27be37adfd"
  associate_public_ip_address       = true
  instance_type                     = "t2.micro"
  #ipv6_address_count                = 
  #ipv6_addresses                    = 
  name                              = "ec2-jenkins"
  #private_ip                        = 
  #user_data                         =
  user_data_base64                  = base64encode(local.user_data)
  vpc_security_group_ids            = [data.aws_security_group.aushafy-sg.id]
  key_name                          = "sshaushafy"
  monitoring                        = true
  subnet_id                         = data.aws_subnet.default.id

  root_block_device = [{
      volume_size = 20
  }]
}