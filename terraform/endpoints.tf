# VPC interface endpoints to keep SSM Session Manager traffic private (no internet dependency)
locals {
  ssm_endpoint_services = compact([
    "com.amazonaws.${var.region}.ssm",
    "com.amazonaws.${var.region}.ssmmessages",
    "com.amazonaws.${var.region}.ec2messages",
  ])
}

resource "aws_vpc_endpoint" "ssm" {
  count             = var.enable_ssm_endpoints ? length(local.ssm_endpoint_services) : 0
  service_name      = local.ssm_endpoint_services[count.index]
  vpc_id            = aws_vpc.main.id
  subnet_ids        = aws_subnet.private[*].id
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = var.enable_ssm_endpoints ? [aws_security_group.vpc_endpoints[0].id] : []

  tags = {
    Name = "${local.name_prefix}-vpc-endpoint-ssm-${count.index + 1}"
  }
}

# Allow HTTPS from the web servers to the SSM interface endpoints
resource "aws_security_group" "vpc_endpoints" {
  count       = var.enable_ssm_endpoints ? 1 : 0
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for SSM VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-vpc-endpoints-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_to_ssm_endpoints" {
  count                        = var.enable_ssm_endpoints ? 1 : 0
  security_group_id            = aws_security_group.vpc_endpoints[0].id
  description                  = "HTTPS 443 from the web server security group"
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}