# Elastic IP for each NAT Gateway located in the same AZ
resource "aws_eip" "nat" {
  count      = var.az_count
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-eip-nat-${count.index + 1}"
  }
}

# One NAT Gateway per AZ, deployed into the public subnet of that AZ
resource "aws_nat_gateway" "main" {
  count         = var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-nat-${count.index + 1}"
  }
}