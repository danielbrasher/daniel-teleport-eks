terraform {
  required_version = ">= 1.16.0" # don't block users or pipelines using newer but compatible minor versions from running plans

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68.0" # allow patches but not minor version changes that might alter resource schemas
    }
  }

  backend "s3" {
    bucket       = "daniel-teleport-eks-tfstate"
    key          = "teleport-eks/dev/terraform.tfstate"
     # hardcoding for now to avoid accidental drift
     # TODO: switch to a standard env var
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true # S3-native locking - don't need a DynamoDB table to handle
  }
}

provider "aws" {
  region = "us-west-1" # ditto previous region note

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Project     = "teleport-eks"
    }
  }
}