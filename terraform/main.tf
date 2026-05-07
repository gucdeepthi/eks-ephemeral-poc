########################################
# ✅ VPC MODULE
########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  name = "${var.env}-eks-poc-vpc"

  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = local.common_tags
}

########################################
# ✅ EKS MODULE
########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  
  version = "~> 19.0"
  
  cluster_name = local.name_prefix

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  create_cloudwatch_log_group = false

  # ✅ Final fixes (critical)
  create_kms_key            = false
  cluster_encryption_config = []

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      desired_size   = 1
      min_size       = 1
      max_size       = 2
    }
  }

  tags = local.common_tags
}
