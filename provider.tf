provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "wellcorp-ops"
    key    = "terraform"
    region = "us-east-1"
  }
}
