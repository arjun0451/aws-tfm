locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Public subnets: one per AZ
  public_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]

  # Private application subnets: one per AZ
  private_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 21)
  ]

  # AZs to use for the two-subnet, two-AZ design
  az_names = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Web server definitions (one per private subnet)
  web_instances = {
    server1 = {
      name             = "server1"
      user_data_script = "server1.sh"
    }
    server2 = {
      name             = "server2"
      user_data_script = "server2.sh"
    }
  }

}