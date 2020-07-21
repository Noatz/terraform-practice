provider "aws" {
  profile = "personal"
  region  = "ap-southeast-2"
  version = "~> 2.8"
}

terraform {
  backend "s3" {
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
  }
}
