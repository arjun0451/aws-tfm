# Design

`aws-tfm` deploys a minimal, self-contained AWS environment for running a single Linux EC2 instance. The configuration is designed to be zero-dependency: when `vpc_id`/`subnet_id` are empty it provisions the full network stack (VPC, internet gateway, security groups, route tables) so the setup works in a fresh AWS account.

## Architecture

```text
                       Internet
                           |
                  [Internet Gateway]
                           |
                     [Route Table]       -> 0.0.0.0/0 via igw
                           |
                 +---------+
                 |  VPC 10.0.0.0/16    |
                 |                     |
                 |   [Public Subnet]   |  10.0.1.0/24
                 |       |             |
                 |   [SecurityGroup]   |  allow 22/tcp from anywhere
                 |       |             |
                 |   [EC2 instance]    |  Amazon Linux 2023, t3.micro
                 +---------------------+
```

## Resource Flow

1. **AMI lookup** – `data.aws_ami.amazon_linux` resolves the most recent Amazon Linux 2023 HVM x86_64 AMI.
2. **Network creation** – if no `vpc_id` given: VPC, Internet Gateway, public Subnet (auto-assign public IP), Route Table with a `0.0.0.0/0` route, and the association.
3. **Security** – `aws_security_group.ssh` permits inbound SSH (22) from any IP and outbound all traffic.
4. **Compute** – `aws_instance.web` launches with an encrypted `gp3` root volume and the SSH key pair.

Using `vpc_id` / `subnet_id` causes Terraform to skip network creation and attach the instance to your existing infrastructure, while the security group is still created inside the provided VPC.

## Key Design Decisions

- **Encrypted root volume** – `encrypted = true` on a `gp3` disk for data-at-rest protection.
- **Auto public IP** – `map_public_ip_on_launch = true` for direct internet reachability.
- **Modular variables** – every tunable (CIDRs, instance type, key, volume size) is parameterized through `variables.tf`.
- **Minimal footprint** – only what is needed for a single host, easy to tear down with `terraform destroy`.

## Outputs

- `vpc_id`, `subnet_id`, `security_group_id`
- `instance_id`, `instance_public_ip`, `instance_private_ip`
- `ssh_connect_command`

## Lifecycle

```bash
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply -auto-approve
terraform destroy
```
