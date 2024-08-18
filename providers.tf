terraform {
  required_version = "~> 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    postgresql = { # This line is what needs to change.
      source = "cyrilgdn/postgresql"
      version = "1.15.0"
    }
  }
}


provider "aws" {
  region = "eu-west-2"
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}

provider "postgresql" {
  # host            = "terraform-20240813204708141400000001.c5cgasmemr78.eu-west-3.rds.amazonaws.com" # localhost SSH Tunnel
  port            = "5433" # Local port of the SSH Tunnel
  username        = "username" # The main username of the Cluster
  password        = "password"
  sslmode         = "require"
  superuser       = true
  connect_timeout = 15
}