data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Role that allows the EC2 web servers to be managed via AWS Systems Manager (SSM)
resource "aws_iam_role" "web_instance" {
  name               = "${local.name_prefix}-web-role"
  description        = "IAM role for the private EC2 web servers (SSM managed)"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${local.name_prefix}-web-role"
  }
}

# Attach the AWS managed SSM core policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.web_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web_instance" {
  name = "${local.name_prefix}-web-instance-profile"
  role = aws_iam_role.web_instance.name

  tags = {
    Name = "${local.name_prefix}-web-instance-profile"
  }
}
