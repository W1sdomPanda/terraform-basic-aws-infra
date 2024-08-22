variable "vpc_parameters" {
  description = "VPC parameters"
  type = map(object({
    cidr_block           = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    tags                 = optional(map(string), {})
  }))
  default = {}
}


variable "subnet_parameters" {
  description = "Subnet parameters"
  type = map(object({
    cidr_block        = string
    vpc_name          = string
    availability_zone = string
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "private_subnet_parameters" {
  description = "Subnet parameters"
  type = map(object({
    cidr_block        = string
    vpc_name          = string
    availability_zone = string
    tags              = optional(map(string), {})
  }))
  default = {}
}



variable "igw_parameters" {
  description = "IGW parameters"
  type = map(object({
    vpc_name = string
    tags     = optional(map(string), {})
  }))
  default = {}
}


variable "rt_parameters" {
  description = "RT parameters"
  type = map(object({
    vpc_name = string
    tags     = optional(map(string), {})
    routes = optional(list(object({
      cidr_block = string
      use_igw    = optional(bool, true)
      gateway_id = string
    })), [])
  }))
  default = {}
}
variable "rt_association_parameters" {
  description = "RT association parameters"
  type = map(object({
    subnet_name = string
    rt_name     = string
  }))
  default = {}
}

variable "ec2_sg" {
  description = "Security group for RDBSM"
  type = map(object({
    vpc_name = string
    name     = string

  }))

  default = {}
}

variable "db_sg" {
  description = "Security group for RDBSM"
  type = map(object({
    vpc_name       = string
    ec2_sg_name    = string
    name           = string
  }))

  default = {}
}

variable "my_ip" {
  description = "IP address"
  type        = string
  sensitive   = true
}

variable "sakura_db_subnet_group" {
  description = "Map of DB subnet group parameters"
  type = map(object({
    name            = string
  }))
}

variable "postgresql_role" {
  description = "postgresql_role"
  type = map(object({
    db_username            = string
    password        = string
  }))
}

variable "psql_grant" {
  description = "psql_grant"
  type = map(object({
    psql_role_name    = string
    db_name           = string
    privileges        = list(string)
  }))
}

variable "sakura_psql_db" {
  description = "Map of PostgreSQL DB instance parameters"
  type = map(object({
    subnet_group           = string
    subnet_name            = string
    allocated_storage      = number
    db_sg                  = string
    engine_version         = string
    engine                 = string
    instance_class         = string
    db_name                = string
    username               = string
    password               = string
    skip_final_snapshot    = bool
    tags                   = optional(map(string), {})
  }))
}

variable "aws_key_pair" {
  description = "Configuration for AWS key pair"
  type = map(object({
    name = string
    filePath = string
  }))
}

variable "sakura_instance" {
  description = "Configuration for EC2"

  type = map(object({
    instance_type = string
    subnet_name = string
    ec2 = string
    ec2_sg_name = string
  }))
}