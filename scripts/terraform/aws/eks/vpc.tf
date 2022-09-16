resource "aws_vpc" "test-eks-vpc" {
  cidr_block = "10.110.0.0/16"

  tags = {
    "Name" = "test-eks-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }

}

resource "aws_eip" "test-eks-eip" {
  vpc = true
  tags = {
    "Name" = "test-eks-public-nat-gateway"
  }
}



resource "aws_nat_gateway" "test-eks-nat-gateway" {
  allocation_id = aws_eip.test-eks-eip.id
  subnet_id = aws_subnet.test-eks-public-subnet[0].id

  tags = {
    "Name" = "test-eks-nat-gateway"
  }
}



# public subnet
resource "aws_subnet" "test-eks-public-subnet" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.110.${count.index+1}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.test-eks-vpc.id

  tags = {
    "Name" = "test-eks-public-${count.index+1 == 1 ? "a" : "c"}"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

# private subnet
resource "aws_subnet" "test-eks-private-subnet" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block = "10.110.1${count.index+1}.0/24"
  vpc_id = aws_vpc.test-eks-vpc.id

  tags = {
    "Name" = "test-eks-private-${count.index+1 == 1 ? "a" : "c"}"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

# trust subnet
resource "aws_subnet" "test-eks-trust-subnet" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block = "10.110.11${count.index+1}.0/24"
  vpc_id = aws_vpc.test-eks-vpc.id

  tags = {
    "Name" = "test-eks-trust-${count.index+1 == 1 ? "a" : "c"}"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}



resource "aws_internet_gateway" "test-eks-igw" {
  vpc_id = aws_vpc.test-eks-vpc.id

  tags = {
    Name = "test-eks-igw"
  }
}



# public route table
resource "aws_route_table" "test-eks-public-route" {
  vpc_id = aws_vpc.test-eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-eks-igw.id
  }

  tags = {
    "Name" = "test-eks-public"
  }
}

# private route table
resource "aws_route_table" "test-eks-private-route" {
  vpc_id = aws_vpc.test-eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.test-eks-nat-gateway.id
  }

  tags = {
    "Name" = "test-eks-private"
  }
}

# trust route table
resource "aws_route_table" "test-eks-trust-route" {
  vpc_id = aws_vpc.test-eks-vpc.id

  tags = {
    "Name" = "test-eks-trust"
  }
}


# public route table association
resource "aws_route_table_association" "test-eks-public-routing" {
  count = 2

  subnet_id      = aws_subnet.test-eks-public-subnet.*.id[count.index]
  route_table_id = aws_route_table.test-eks-public-route.id
}

# private route table association
resource "aws_route_table_association" "test-eks-private-routing" {
  count = 2

  subnet_id      = aws_subnet.test-eks-private-subnet.*.id[count.index]
  route_table_id = aws_route_table.test-eks-private-route.id
}

# trust route table association
resource "aws_route_table_association" "test-eks-trust-routing" {
  count = 2

  subnet_id      = aws_subnet.test-eks-trust-subnet.*.id[count.index]
  route_table_id = aws_route_table.test-eks-trust-route.id
}