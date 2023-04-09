######################
# VPC and Sbunet
######################
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "public_1d" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1d"
  cidr_block        = "10.0.3.0/24"
}

resource "aws_subnet" "private_1a" {
  count             = var.enable_private_subnet == true ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.10.0/24"
}

resource "aws_subnet" "private_1c" {
  count             = var.enable_private_subnet == true ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.20.0/24"
}

resource "aws_subnet" "private_1d" {
  count             = var.enable_private_subnet == true ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1d"
  cidr_block        = "10.0.30.0/24"
}

######################
# Internet Gateway
######################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

######################
# ElasticIP & Nat Gateway
######################
resource "aws_eip" "nat_1a" {
  count = var.enable_private_subnet == true ? 1 : 0
  vpc   = true
}

resource "aws_eip" "nat_1c" {
  count = var.enable_private_subnet && var.enable_multi_az_nat_gw == true ? 1 : 0
  vpc   = true
}

resource "aws_eip" "nat_1d" {
  count = var.enable_private_subnet && var.enable_multi_az_nat_gw == true ? 1 : 0
  vpc   = true
}

resource "aws_nat_gateway" "nat_1a" {
  count         = var.enable_private_subnet == true ? 1 : 0
  subnet_id     = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_1a[0].id
}

resource "aws_nat_gateway" "nat_1c" {
  count         = var.enable_private_subnet && var.enable_multi_az_nat_gw == true ? 1 : 0
  subnet_id     = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c[0].id
}

resource "aws_nat_gateway" "nat_1d" {
  count         = var.enable_private_subnet && var.enable_multi_az_nat_gw == true ? 1 : 0
  subnet_id     = aws_subnet.public_1d.id
  allocation_id = aws_eip.nat_1d[0].id
}

######################
# RouteTable
######################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_1d.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_1a" {
  count  = var.enable_private_subnet == true ? 1 : 0
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "private_1c" {
  count  = var.enable_private_subnet == true ? 1 : 0
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "private_1d" {
  count  = var.enable_private_subnet == true ? 1 : 0
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "private_1a" {
  count                  = var.enable_private_subnet == true ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a[0].id
  nat_gateway_id         = aws_nat_gateway.nat_1a[0].id
}

resource "aws_route" "private_1c" {
  count                  = var.enable_private_subnet == true ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c[0].id
  nat_gateway_id         = var.enable_multi_az_nat_gw == true ? aws_nat_gateway.nat_1c[0].id : aws_nat_gateway.nat_1a[0].id
}

resource "aws_route" "private_1d" {
  count                  = var.enable_private_subnet == true ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1d[0].id
  nat_gateway_id         = var.enable_multi_az_nat_gw == true ? aws_nat_gateway.nat_1d[0].id : aws_nat_gateway.nat_1a[0].id
}

resource "aws_route_table_association" "private_1a" {
  count          = var.enable_private_subnet == true ? 1 : 0
  subnet_id      = aws_subnet.private_1a[0].id
  route_table_id = aws_route_table.private_1a[0].id
}

resource "aws_route_table_association" "private_1c" {
  count          = var.enable_private_subnet == true ? 1 : 0
  subnet_id      = aws_subnet.private_1c[0].id
  route_table_id = aws_route_table.private_1c[0].id
}

resource "aws_route_table_association" "private_1d" {
  count          = var.enable_private_subnet == true ? 1 : 0
  subnet_id      = aws_subnet.private_1d[0].id
  route_table_id = aws_route_table.private_1d[0].id
}
