terraform {
  required_providers {
    aws = {
      version               = "~> 4.9"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc, aws.core-network-services, aws.us-east-1]
    }
  }
  required_version = ">= 1.1.7"
}
