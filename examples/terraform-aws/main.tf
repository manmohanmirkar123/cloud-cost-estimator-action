terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Sample resources for cost estimation
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"  # ~$8/mo

  tags = {
    Name = "web"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-cost-data-bucket"

  tags = {
    Name = "data"
  }
}

