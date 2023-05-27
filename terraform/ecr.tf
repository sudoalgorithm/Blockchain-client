#ECR Repository
resource "aws_ecr_repository" "blockchain_client_repo" {
  name                 = "eth_blockchain_client"
  image_tag_mutability = "MUTABLE"
}

#ECR Policy
resource "aws_ecr_lifecycle_policy" "blockchain_client_repo_policy" {
  repository = aws_ecr_repository.blockchain_client_repo.name
  policy     = data.local_file.ecr_lifecycle_policy
}

#ECR Image Scan Configuration
resource "aws_ecr_registry_scanning_configuration" "blockchain_client_svc_img" {
  scan_type = "ENHANCED"
  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

# Build docker image and push to ECR
resource "docker_image" "blockchain_client_svc_img" {
  name = "${aws_ecr_repository.blockchain_client_repo.repository_url}:v1.0"

  build {
    context    = "application"
    dockerfile = "client.Dockerfile"
  }
}