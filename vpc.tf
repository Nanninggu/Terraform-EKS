provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# 서브넷
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                          = "public-subnet-a"
    "kubernetes.io/role/elb"      = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                          = "public-subnet-b"
    "kubernetes.io/role/elb"      = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                          = "private-subnet-a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name                          = "private-subnet-b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-gateway"
  }
}

# 라우트 테이블 (인터넷 게이트웨이)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# nat 게이트웨이
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat-gateway"
  }
}

# eip
resource "aws_eip" "nat" {
  domain = "vpc"
}

# 라우트 테이블
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}