
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

data "aws_availability_zones" "zones" {}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  count = 2
  subnet_id      = aws_subnet.sb.*.id[count.index]
  route_table_id = aws_route_table.rt.id
}

resource "aws_subnet" "sb" {
  count = 2

  availability_zone       = data.aws_availability_zones.zones.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id
}


