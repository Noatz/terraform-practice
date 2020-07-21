module "vpc" {
  source = "./modules/vpc"

  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  public_subnets  = ["10.0.0.10/24", "10.0.0.11/24", "10.0.0.12/24"]
  private_subnets = ["10.0.0.20/24", "10.0.0.21/24", "10.0.0.22/24"]

  tags = {
    Environment = var.env
    Terraform   = true
  }
}

module "webserver" {
  source = "./modules/webserver"

  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
}