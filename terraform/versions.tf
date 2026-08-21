terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Remote state. Create the bucket once, out of band, then uncomment.
  # backend "s3" {
  #   bucket       = "daniel-teleport-tfstate"
  #   key          = "teleport-eks/dev/terraform.tfstate"
  #   region       = "us-west-1"
  #   encrypt      = true
  #   use_lockfile = true # S3-native locking (TF >= 1.10), no DynamoDB table needed
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}
