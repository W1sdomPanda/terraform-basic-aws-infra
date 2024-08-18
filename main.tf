data "aws_ami" "ubuntu" {
  most_recent = "true"

  filter {
    name = "name"
    values = [ "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data aws_iam_policy_document "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document "s3_read_access" {
  statement {
    actions = ["s3:Get*", "s3:List*"]

    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_vpc" "this" {
  for_each             = var.vpc_parameters
  cidr_block           = each.value.cidr_block
  enable_dns_support   = each.value.enable_dns_support
  enable_dns_hostnames = each.value.enable_dns_hostnames
  tags = merge(each.value.tags, {
    Name : each.key
  })
}

resource "aws_subnet" "this" {
  for_each   = var.subnet_parameters
  vpc_id     = aws_vpc.this[each.value.vpc_name].id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(each.value.tags, {
    Name : each.key
  })
}

resource "aws_subnet" "private_subnet" {
  for_each   = var.private_subnet_parameters
  vpc_id     = aws_vpc.this[each.value.vpc_name].id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(each.value.tags, {
    Name : each.key
  })
}

resource "aws_internet_gateway" "this" {
  for_each = var.igw_parameters
  vpc_id   = aws_vpc.this[each.value.vpc_name].id
  tags = merge(each.value.tags, {
    Name : each.key
  })
}

resource "aws_route_table" "this" {
  for_each = var.rt_parameters
  vpc_id   = aws_vpc.this[each.value.vpc_name].id
  tags = merge(each.value.tags, {
    Name : each.key
  })

  dynamic "route" {
    for_each = each.value.routes
    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.use_igw ? aws_internet_gateway.this[route.value.gateway_id].id : route.value.gateway_id
    }
  }
}

resource "aws_route_table_association" "this" {
  for_each       = var.rt_association_parameters
  subnet_id      = aws_subnet.this[each.value.subnet_name].id
  route_table_id = aws_route_table.this[each.value.rt_name].id
}

resource "aws_security_group" "this" {
  for_each = var.ec2_sg

  vpc_id   = aws_vpc.this[each.value.vpc_name].id

  name     = each.value.name

  ingress {
    description = "ALL HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow SSH"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    description = "allow SSH"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  for_each = var.db_sg
  vpc_id   = aws_vpc.this[each.value.vpc_name].id
  name     = each.value.name

  ingress {
    description     = "ALL HTTP"
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "tcp"
    security_groups = [aws_security_group.this[each.value.ec2_sg_name].id]
  }

}

resource "aws_db_subnet_group" "sakura_db_subnet_group" {
  for_each = var.sakura_db_subnet_group

  name = each.value.name
  subnet_ids = [ for subnet in aws_subnet.private_subnet : subnet.id ]

}


resource "aws_db_instance" "sakura_db" {
  for_each  = var.sakura_psql_db

  vpc_security_group_ids = [ aws_security_group.db_sg[each.value.db_sg].id]

  db_subnet_group_name = aws_db_subnet_group.sakura_db_subnet_group[each.value.subnet_group].id


  allocated_storage    = each.value.allocated_storage
  engine               = each.value.engine
  engine_version       = each.value.engine_version
  instance_class       = each.value.instance_class
  username             = each.value.username
  password             = each.value.password
  db_name              = each.value.db_name

  tags = merge(each.value.tags, {
    Name = each.key
  })
}

resource "postgresql_role" "this" {
  
  for_each  = var.postgresql_role

  name       = each.value.db_username
  login      = true
  password   = each.value.password

  depends_on = [
    aws_db_instance.sakura_db
  ]
}

resource "postgresql_grant" "this" {
  for_each  = var.psql_grant

  role        = postgresql_role.this[each.value.psql_role_name].name
  database    = aws_db_instance.sakura_db[each.value.db_name].db_name
  schema      = "public"
  object_type = "table"
  privileges  = each.value.privileges

  depends_on = [
    postgresql_role.this
  ]
}

resource "aws_key_pair" "kp" {
  for_each = var.aws_key_pair

  key_name     = each.value.name
  public_key = file(each.value.filePath)
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"

  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

resource "aws_iam_role_policy" "join_policy" {
  depends_on = [aws_iam_role.ec2_iam_role]
  name       = "join_policy"
  role       = "${aws_iam_role.ec2_iam_role.name}"

  policy = "${data.aws_iam_policy_document.s3_read_access.json}"
}

resource "aws_iam_instance_profile" "instance_profile1" {
  name = "instance_profile"
  role = "${aws_iam_role.ec2_iam_role.name}"
}

resource "aws_instance" "instance" {
  for_each  = var.sakura_instance

  ami = data.aws_ami.ubuntu.id

  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.this[each.value.subnet_name].id
  key_name               = aws_key_pair.kp[each.value.ec2].key_name
  vpc_security_group_ids = [aws_security_group.this[each.value.ec2_sg_name].id]


  iam_instance_profile = "${aws_iam_instance_profile.instance_profile1.name}"

  associate_public_ip_address = true
}

resource "aws_s3_bucket" "sakura_s3" {
  bucket = "sakura-group123214135"

  tags = {
    Name        = "S3 bucket for sakura group"
  }
}