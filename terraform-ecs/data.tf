data "aws_caller_identity" "current" {}

data "aws_ecr_image" "container_image" {
  repository_name = var.ecr_repo_name
  image_tag       = "v1"
}

data "aws_lb" "blockchain_client_alb_name" {
  name = "blockchain-client-alb"
}