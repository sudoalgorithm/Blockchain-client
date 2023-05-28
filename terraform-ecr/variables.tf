variable "aws_region" {
  type        = string
  description = "Targeted AWS Region"
  default     = "us-east-1"
}

variable "ecr_repo_name" {
  type        = string
  description = "Name of the ECR Repo"
  default     = "eth-blockchain-client"
}

variable "env" {
  type        = string
  description = "Target Environment example dev, staging and production"
  default = "dev"
}