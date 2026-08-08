output "vpc_id" {
  description = "ID of the dedicated VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the dedicated VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private application subnets (one per AZ)"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways (one per AZ)"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Elastic IPs of the NAT gateways (one per AZ)"
  value       = aws_eip.nat[*].public_ip
}

output "web_instance_ids" {
  description = "IDs of the private EC2 web servers"
  value       = aws_instance.web[*].id
}

output "web_instance_private_ips" {
  description = "Private IPs of the EC2 web servers"
  value       = aws_instance.web[*].private_ip
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the internet-facing Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.web.arn
}

output "web_security_group_id" {
  description = "ID of the EC2 web server security group"
  value       = aws_security_group.web.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ssm_start_session_commands" {
  description = "Commands to open a Session Manager session to each private web server"
  value = [
    for i in range(var.az_count) :
    "aws ssm start-session --target ${aws_instance.web[i].id} --region ${var.region}"
  ]
}
