data "aws_caller_identity" "current" {}

data "aws_ecr_authorization_token" "token" {}

data "local_file" "ecr_lifecycle_policy" {
  filename = "policies/ecr_lifecycle_policy.json"
}