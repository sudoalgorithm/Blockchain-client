locals {
  created_by  = "terraform"
  aws_ecr_url = "${data.aws_caller_identity.current.account_id}.ethclient.ecr.${var.aws_region}.amazonaws.com"
}