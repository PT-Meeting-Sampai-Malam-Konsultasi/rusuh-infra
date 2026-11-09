variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "One CIDR per availability zone, for public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "public_subnet_cidrs must have one entry per availability zone."
  }
}

variable "private_subnet_cidrs" {
  description = "One CIDR per availability zone, for private subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "private_subnet_cidrs must have one entry per availability zone."
  }
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway for private subnets (off by default: cost; see README.md)."
  type        = bool
  default     = false
}
