# Application Load Balancer security group
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for the internet-facing Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# Allow HTTP 80 from the internet to the ALB
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP 80 from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_port
  to_port           = var.web_port
  ip_protocol       = "tcp"
}

# ALB needs to reach the web servers on port 80 inside the VPC
resource "aws_vpc_security_group_egress_rule" "alb_http_to_web" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP 80 to web servers in VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = var.web_port
  to_port           = var.web_port
  ip_protocol       = "tcp"
}

# Web server security group (private instances)
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for the private EC2 web servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

# Allow HTTP 80 ONLY from the ALB security group (no direct internet access)
resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP 80 from the ALB security group only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.web_port
  to_port                      = var.web_port
  ip_protocol                  = "tcp"
}

# Outbound for software updates and SSM agent communication
resource "aws_vpc_security_group_egress_rule" "web_outbound_https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS 443 to the internet (updates, SSM)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_outbound_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP 80 to the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}
