variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "rusuh"
}

variable "environment" {
  description = "Environment name (demo = evaluation environment for 13 Nov 2026)."
  type        = string
  default     = "demo"
}

variable "region" {
  description = "AWS region for all resources in this environment."
  type        = string
  default     = "ap-southeast-3"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across (2 AZs for demo)."
  type        = list(string)
  default     = ["ap-southeast-3a", "ap-southeast-3b"]
}

variable "public_subnet_cidrs" {
  description = "One CIDR per availability zone, for public subnets (ALB + demo ECS)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "One CIDR per availability zone, for private subnets (data)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway for private subnets (off by default: ~$30+/month; see modules/network/README.md)."
  type        = bool
  default     = false
}
