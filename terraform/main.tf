########################################
# VPC MODULE
########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.env}-eks-poc-vpc"

  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false   # FIXED (avoid cost + failure)
  single_nat_gateway = false
  
  tags = local.common_tags
}

########################################
# EKS MODULE (STABLE FIXED VERSION)
########################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name = local.name_prefix
  cluster_version = "1.29"

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  cluster_endpoint_public_access = true  
  
########################################
# FIX: NODE GROUP ADDED
########################################

  eks_managed_node_groups = {
    default = {
	
      desired_size = 1
      min_size     = 1
      max_size     = 2

      instance_types = ["t3.micro"]

      capacity_type = "ON_DEMAND"
	  
	  ami_type = "AL2_x86_64"
	  
    }
  }

  tags = local.common_tags
  
}