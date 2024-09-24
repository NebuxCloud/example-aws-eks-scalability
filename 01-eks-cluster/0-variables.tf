variable "eks_cluster_name" {
  default     = "example-cluster"
  description = "The name of the EKS cluster"
}

variable "eks_cluster_version" {
  default     = "1.30"
  description = "The version of the EKS cluster"
}

variable "aws_profile" {
  default     = "example-profile"
  description = "The AWS profile"
}

variable "aws_region" {
  default     = "eu-west-1"
  description = "The AWS region"
}

variable "aws_vpc_public_subnets" {
  type = map(object({
    cidr_block = string
    az         = string
  }))

  default = {
    "public-a" = {
      cidr_block = "10.0.1.0/24"
      az         = "eu-west-1a"
    }
    "public-b" = {
      cidr_block = "10.0.2.0/24"
      az         = "eu-west-1b"
    }
    "public-c" = {
      cidr_block = "10.0.3.0/24"
      az         = "eu-west-1c"
    }
  }
}

variable "aws_vpc_private_subnets" {
  type = map(object({
    cidr_block = string
    az         = string
  }))

  default = {
    "private-a" = {
      cidr_block = "10.0.10.0/24"
      az         = "eu-west-1a"
    }
    "private-b" = {
      cidr_block = "10.0.20.0/24"
      az         = "eu-west-1b"
    }
    "private-c" = {
      cidr_block = "10.0.30.0/24"
      az         = "eu-west-1c"
    }
  }
}
