provider "aws" {
  profile = "default"
  region  = "ap-southeast-2"
  version = "~> 2.8"
}

terraform {
  backend "s3" {
    bucket = "terraform-j38sj2s3w"
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
  }
}
