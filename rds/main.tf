##############################################################
# Konfigurasi Providers AWS, wajib di setiap resource
##############################################################
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

##############################################################
# Data sources untuk mengambil informasi VPC, subnets dan security group
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

##############################################################
# menggunakan module secara online dari Terraform Registry
##############################################################
module "rds" {
  source  = "terraform-aws-modules/rds/aws" // ini repository online terraform registry
  version = "2.20.0"
  
  # nama dari RDS Instance
  identifier = "RDS_NAME"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.micro" 
  allocated_storage = 5 # kapasitas storage dalam Gigabytes
  storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name     = "DB_NAME" # nama dari initial database yang mau dibuat
  username = "DB_USERNAME"
  password = "DB_PASSWORD"
  port     = "3306"

  vpc_security_group_ids = [data.aws_security_group.default.id]

  # setting untuk multiple AZs apabila mau menerapkan High-Available
  multi_az = true

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = var.owner
    Environment = "dev"
  }
  
  # agar RDS bisa diakses dari luar/public
  publicly_accessible = true 

  # enabled_cloudwatch_logs_exports = ["audit", "general"]
  enabled_cloudwatch_logs_exports = [] # disable log monitoring cloudwatch

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.all.ids

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "17:00-20:00" // UTC Time, kalau indonesia time kisaran pukul 12 malam sampai pukul 3 pagi. ref: https://savvytime.com/converter/utc-to-wib

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "aushafyrds"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]
}