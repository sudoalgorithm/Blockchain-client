variable "aws_region" {
  type        = string
  description = "Targeted AWS Region"
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "Name of the vpc"
}

variable "env" {
  type        = string
  description = "Target Environment example dev, staging and production"
}

variable "vpc_cidr_range" {
  type        = string
  description = "IPv4 VPC CIDR range"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "IPv4 CIDR range for subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_name" {
  type        = string
  description = "Name of the public subnets"
  default     = "Public Subnet"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "IPv4 CIDR range for subnets"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "private_subnet_name" {
  type        = string
  description = "Name of the private subnets"
  default     = "Private Subnet"
}

variable "azs" {
  type        = list(string)
  description = "AWS Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "internet_gateway" {
  type        = string
  description = "Name of the internet gateway"
}

variable "public_route_table" {
  type        = string
  description = "Name of the route associated to public subnet"
}

variable "public_destination_cidr_block" {
  type        = string
  description = "Route IPv4 Address"
  default     = "0.0.0.0/0"
}

variable "private_destination_cidr_block" {
  type        = string
  description = "Route IPv4 Address"
  default     = "0.0.0.0/0"
}

variable "alb_security_group" {
  type        = string
  description = "Security group name For ALB"
  default     = "ecs-alb-security-group"
}

variable "ecs_security_group" {
  type        = string
  description = "Security group name For ALB"
  default     = "ecs-security-group"
}

variable "container_port" {
  type        = string
  description = "Exposed container port"
}