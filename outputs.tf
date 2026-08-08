output "vpc_id" {
  description = "The ID of the VPC."
  value       = var.vpc_id != "" ? var.vpc_id : aws_vpc.main[0].id
}

output "subnet_id" {
  description = "The ID of the subnet used by the instance."
  value       = var.subnet_id != "" ? var.subnet_id : aws_subnet.main[0].id
}

output "security_group_id" {
  description = "The ID of the SSH security group."
  value       = aws_security_group.ssh.id
}

output "instance_id" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance."
  value       = aws_instance.web.private_ip
}

output "ssh_connect_command" {
  description = "Command to SSH into the instance using the configured key pair."
  value       = try("ssh -i ~/.ssh/${aws_instance.web.key_name}.pem ec2-user@${aws_instance.web.public_ip}", "ssh ec2-user@<public-ip>")
}
