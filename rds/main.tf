##############################################################
# Konfigurasi Providers AWS, wajib di setiap root directory
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
# Data sources untuk mengambil informasi VPC, subnets
##############################################################

# mengambil informasi VPC default
data "aws_vpc" "default" {
  default = true
}

# mengambil informasi subnets id dari vpc default
data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

# mengambil informasi Security Group yang berada di default VPC
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

##############################################################
# menggunakan module Security Group secara online dari Terraform Registry
##############################################################
module "security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.16.0"
  # insert the 2 required variables here
  
  # nama security group
  name = "rds"
  description = "Security Group for RDS"
  vpc_id = data.aws_vpc.default.id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = [ "mysql-tcp" ] # https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest?tab=inputs
  egress_rules = [ "all-all" ] # https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest?tab=inputs
}


##############################################################
# menggunakan module RDS secara online dari Terraform Registry
##############################################################
module "rds" {
  source  = "terraform-aws-modules/rds/aws" // ini repository online terraform registry
  version = "2.20.0"
  
  # nama dari RDS Instance
  identifier = "RDS_NAME" # CHANGE ME!

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.micro" 
  allocated_storage = 5 # kapasitas storage dalam Gigabytes
  storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name     = "DB_NAME" # CHANGE ME! nama dari initial database yang mau dibuat
  username = "DB_USERNAME" # CHANGE ME!
  password = "DB_PASSWORD" # CHANGE ME!
  port     = "3306"

  #vpc_security_group_ids = [data.aws_security_group.default.id] # jika kita ingin pakai security group default, uncomment ini
  vpc_security_group_ids = [module.security-group.this_security_group_id] # menggunakan Security Group yang tadi sudah dibuat

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
  final_snapshot_identifier = "SNAPSHOT_NAME" # CHANGE ME!

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