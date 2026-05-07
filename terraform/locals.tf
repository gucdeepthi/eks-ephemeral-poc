locals {
  name_prefix = "${var.env}-eks-poc-${var.client}-${var.service}-b${var.build_id}"

  common_tags = {
    Environment = var.env
    Project     = "eks-poc"
    Client      = var.client
    Service     = var.service
    Owner       = "devops"
    ManagedBy   = "terraform"
    Build       = var.build_id
    CreatedOn   = formatdate("YYYY-MM-DD", timestamp())
  }
}