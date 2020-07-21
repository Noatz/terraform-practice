resource "aws_vpc" "main" {
  cidr_block = var.cidr

  tags = merge(var.tags, { Name = "vpc-main" })
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.public_subnets[count.index]

  tags = merge(var.tags, { Name = "public-${count.index}" })
}


resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnets[count.index]

  tags = merge(var.tags, { Name = "private-${count.index}" })
}

resource "aws_eip" "nat" {
  count = length(var.private_subnets)

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  count = length(var.private_subnets)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.private[count.index].id

  tags = merge(var.tags, { Name = "ngw-${count.index}" })
}