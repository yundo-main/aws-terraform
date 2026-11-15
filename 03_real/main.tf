# ============================================================
# main.tf — 02_practice 내용을 변수화해 단일 state로 관리
# VPC → 서브넷 → IGW/NGW → 라우팅 → SG → EC2 → RDS
# ============================================================

# ---------------- VPC ----------------

resource "aws_vpc" "terraform_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ---------------- 서브넷 ----------------

resource "aws_subnet" "terraform_pub_subnet_2a" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.pub_subnet_cidrs[0]
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.project_name}-pub-subnet-2a"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "terraform_pub_subnet_2c" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.pub_subnet_cidrs[1]
  availability_zone       = var.azs[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.project_name}-pub-subnet-2c"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "terraform_pri_subnet_2a" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.pri_subnet_cidrs[0]
  availability_zone = var.azs[0]

  tags = {
    Name                                          = "${var.project_name}-pri-subnet-2a"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "terraform_pri_subnet_2c" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.pri_subnet_cidrs[1]
  availability_zone = var.azs[1]

  tags = {
    Name                                          = "${var.project_name}-pri-subnet-2c"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/terraform-eks-cluster" = "shared"
  }
}

# ---------------- 게이트웨이 ----------------

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_eip" "terraform_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "terraform_ngw" {
  allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.terraform_pub_subnet_2a.id

  tags = {
    Name = "${var.project_name}-ngw"
  }
}

# ---------------- 라우팅 ----------------

resource "aws_route_table" "terraform_pub_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-pub-rt"
  }
}

resource "aws_route_table" "terraform_pri_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-pri-rt"
  }
}

resource "aws_route" "terraform_pub_rt" {
  route_table_id         = aws_route_table.terraform_pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.terraform_igw.id
}

resource "aws_route" "terraform_pri_rt" {
  route_table_id         = aws_route_table.terraform_pri_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.terraform_ngw.id
}

resource "aws_route_table_association" "terraform_pub_rt_associate_2a" {
  subnet_id      = aws_subnet.terraform_pub_subnet_2a.id
  route_table_id = aws_route_table.terraform_pub_rt.id
}

resource "aws_route_table_association" "terraform_pub_rt_associate_2c" {
  subnet_id      = aws_subnet.terraform_pub_subnet_2c.id
  route_table_id = aws_route_table.terraform_pub_rt.id
}

resource "aws_route_table_association" "terraform_pri_rt_associate_2a" {
  subnet_id      = aws_subnet.terraform_pri_subnet_2a.id
  route_table_id = aws_route_table.terraform_pri_rt.id
}

resource "aws_route_table_association" "terraform_pri_rt_associate_2c" {
  subnet_id      = aws_subnet.terraform_pri_subnet_2c.id
  route_table_id = aws_route_table.terraform_pri_rt.id
}

# ---------------- 보안 그룹 ----------------

# Bastion SG — 실습용 전체 개방 (운영에서는 CIDR 축소 권장)
resource "aws_security_group" "terraform_sg_bastion" {
  name        = "${var.project_name}-sg-bastion"
  description = "for Bastion Server"
  vpc_id      = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-sg-bastion"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for ping"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for HTTPS"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "for DB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS SG — 배스천 SG를 가진 인스턴스에서만 3306 허용
resource "aws_security_group" "terraform_sg_rds" {
  name        = "${var.project_name}-sg-rds"
  description = "for RDS MariaDB"
  vpc_id      = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-sg-rds"
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.terraform_sg_bastion.id]
    description     = "MariaDB from bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- EC2 (배스천) ----------------

resource "aws_instance" "terraform_pub_ec2_bastion_2a" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  vpc_security_group_ids      = [aws_security_group.terraform_sg_bastion.id]
  subnet_id                   = aws_subnet.terraform_pub_subnet_2a.id
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    tags = {
      Name = "${var.project_name}-pub-ec2-bastion-2a"
    }
  }

  tags = {
    Name = "${var.project_name}-pub-ec2-bastion-2a"
  }
}

# ---------------- RDS ----------------

resource "aws_db_subnet_group" "terraform_rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.terraform_pri_subnet_2a.id, aws_subnet.terraform_pri_subnet_2c.id]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

resource "aws_db_parameter_group" "terraform_mariadb_parameter_group" {
  name        = "${var.project_name}-mariadb-parameter-group"
  family      = "mariadb10.11"
  description = "Custom parameter group for MariaDB"

  parameter {
    name  = "max_connections"
    value = "150"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  dynamic "parameter" {
    for_each = ["character_set_client", "character_set_connection", "character_set_database",
    "character_set_filesystem", "character_set_results", "character_set_server"]
    content {
      name  = parameter.value
      value = "utf8mb4"
    }
  }

  dynamic "parameter" {
    for_each = ["collation_connection", "collation_server"]
    content {
      name  = parameter.value
      value = "utf8mb4_unicode_ci"
    }
  }

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }
}

resource "aws_db_instance" "terraform_mariadb_rds" {
  identifier_prefix      = "${var.project_name}-mariadb-rds"
  allocated_storage      = 10
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.terraform_mariadb_parameter_group.name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.terraform_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.terraform_sg_rds.id]

  tags = {
    Name = "${var.project_name}-mariadb-rds"
  }
}
