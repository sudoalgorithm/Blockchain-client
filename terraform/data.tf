data "aws_caller_identity" "current" {}

data "aws_ecr_authorization_token" "token" {}

data "local_file" "ecr_lifecycle_policy" {
  filename = "policies/ecr_lifecycle_policy.json"
}

data "aws_ecr_image" "container_image" {
  repository_name = var.ecr_repo_name
  image_tag       = "v1"
}