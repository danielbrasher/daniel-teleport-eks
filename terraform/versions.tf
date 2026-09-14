terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.63"
    }
  }

  # stores TF state in production
  backend "s3" {
    bucket       = "daniel-teleport-eks-tfstate"
    key          = "teleport-eks/dev/terraform.tfstate"
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true # S3-native locking - don't need a DynamoDB table to handle
  #}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}
