# aws-tfm

Terraform configuration that provisions a secure AWS environment for a Linux EC2 instance. When no existing VPC/subnet is provided, it creates a full network stack (VPC, internet gateway, public subnet, route table) and launches an Amazon Linux 2023 instance with an encrypted root volume.

## Resources

- VPC (`10.0.0.0/16`) with a public subnet (`10.0.1.0/24`)
- Internet Gateway and route table (default route `0.0.0.0/0`)
- Security group allowing SSH (port 22) inbound and all outbound traffic
- EC2 instance (`t3.micro` by default) with an encrypted `gp3` root volume

## Prerequisites

- Terraform `>= 1.3`
- AWS credentials configured (default profile or via `AWS_PROFILE`/`AWS_ACCESS_KEY_ID`)
- An existing EC2 key pair in the target region for SSH access

## Usage

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Specify the key pair and other settings via `terraform.tfvars`:

```hcl
key_name = "ocpkey"
```

To reuse an existing network instead of creating a new VPC/subnet:

```hcl
vpc_id    = "vpc-1234567"
subnet_id = "subnet-1234abcd"
```

## Design

See [docs/design.md](docs/design.md) for a detailed design walkthrough.

## License

MIT
