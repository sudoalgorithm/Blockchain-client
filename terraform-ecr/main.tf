#ECR Repository
resource "aws_ecr_repository" "blockchain_client_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = var.ecr_repo_name
    environment = var.env
    created_by  = local.created_by
  }
}

#ECR Policy
resource "aws_ecr_lifecycle_policy" "blockchain_client_repo_policy" {
  repository = aws_ecr_repository.blockchain_client_repo.name
  policy     = jsonencode({
    "rules":[{
        "rulePriority": 1,
        "description": "Keep last 10 images",
        "selection":{
            "tagStatus": "tagged",
            "tagPrefixList": ["v"],
            "countType": "imageCountMoreThan",
            "countNumber": 10
        },
        "action": {
            "type": "expire"
        }
    }]
})
}

# Build docker image and push to ECR
resource "docker_image" "blockchain_client_svc_img" {
  name = "${aws_ecr_repository.blockchain_client_repo.repository_url}:v1.0"

  build {
    path = "../"
    dockerfile = "Dockerfile"
  }
}

