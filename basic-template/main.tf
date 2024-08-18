variable "aws_secret_key" {
  description = "aws_secret_key"
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  description = "aws_access_key"
  type        = string
  sensitive   = true
}
provider "aws" {
  region = "eu-west-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

module "vpc" {
  source = "../"
  vpc_parameters = {
    vpc_sakura = {
      cidr_block = "10.0.0.0/16"
    }
  }
  subnet_parameters = {
    # Public
    subnet_public_1 = {
      cidr_block        = "10.0.1.0/24"
      vpc_name          = "vpc_sakura"
      availability_zone = "eu-west-2a"
    }
    subnet_public_2 = {
      cidr_block        = "10.0.2.0/24"
      vpc_name          = "vpc_sakura"
      availability_zone = "eu-west-2b"
    }
    subnet_public_3 = {
      cidr_block        = "10.0.3.0/24"
      vpc_name          = "vpc_sakura"
      availability_zone = "eu-west-2c"
    }
  }

  private_subnet_parameters = {
    subnet_private_4 = {
      cidr_block        = "10.0.4.0/24"
      vpc_name          = "vpc_sakura"
      availability_zone = "eu-west-2a"
    }
    subnet_private_5 = {
      cidr_block        = "10.0.5.0/24"
      vpc_name          = "vpc_sakura"
      availability_zone = "eu-west-2b"
    }
    subnet_private_6 = {
      cidr_block        = "10.0.6.0/24"
      vpc_name          = "vpc_sakura"
      availability_zone = "eu-west-2c"
    }
  }

  igw_parameters = {
    igw1 = {
      vpc_name = "vpc_sakura"
    }
  }
  rt_parameters = {
    rt1 = {
      vpc_name = "vpc_sakura"
      routes = [{
        cidr_block = "0.0.0.0/0"
        gateway_id = "igw1"
        }
      ]
    }
  }
  rt_association_parameters = {
    assoc1 = {
      subnet_name = "subnet_public_1"
      rt_name     = "rt1"
    }
    assoc2 = {
      subnet_name = "subnet_public_2"
      rt_name     = "rt1"
    }
    assoc3 = {
      subnet_name = "subnet_public_3"
      rt_name     = "rt1"
    }
  }

  ec2_sg = {
    sg_sakura = {
      vpc_name          = "vpc_sakura"
      name              = "EC2 sg"
    }
  }

  db_sg = {
    psql = {
      vpc_name          = "vpc_sakura"
      ec2_sg_name       = "sg_sakura"
      name              = "DB PSQL"
    }
  }

  my_ip = "176.122.119.139"
  
  sakura_db_subnet_group = {
    sakura_db_subnet_group = {
      name            = "sakura_db_subnet_group"
    }
  }

  sakura_psql_db = {
    sakura_psql_db = {
      subnet_group      = "sakura_db_subnet_group"
      subnet_name       = "subnet_private_4"
      db_sg             = "psql"
      allocated_storage = 20
      engine_version    = "16.4"
      engine            = "postgres"
      instance_class    = "db.t3.micro"
      db_name           = "db_name"
      username          = "username"
      password          = "password"
    }
  }
  postgresql_role = {
    postgresql_role = {
      db_username     = "username"
      password = "password"
    }
  }

  psql_grant = {
    psql_grant = {
      psql_role_name = "postgresql_role"
      db_name     = "sakura_psql_db"
      privileges  = ["ALL"]
    }
  }
 
  aws_key_pair = {
    ec2 = {
      name = "ssh_public"
      filePath = "/Users/vladyslav.s/.ssh/own.pub" 
    }
  }

  sakura_instance = {
    free_instance = {
      instance_type = "t3.micro"
      subnet_name   = "subnet_public_1"
      ec2 = "ec2"
      ec2_sg_name   = "sg_sakura"
    }
  }
}