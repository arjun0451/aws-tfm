# Latest Amazon Linux 2023 AMI for ap-southeast-1 (x86_64)
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Private EC2 web servers - one per AZ, no public IP
resource "aws_instance" "web" {
  count                       = var.az_count
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[count.index].id
  availability_zone           = local.az_names[count.index]
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.web_instance.name
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = false
  user_data                   = file("${path.module}/user-data/${local.web_instances["server${count.index + 1}"].user_data_script}")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = local.web_instances["server${count.index + 1}"].name
  }
}
