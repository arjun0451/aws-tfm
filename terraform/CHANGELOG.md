# Changelog

All notable changes to this Terraform project are documented in this file.

## [0.1.0] - 2026-08-08

### Added — Initial production AWS web infrastructure

- **Networking**
  - Dedicated VPC `10.20.0.0/16` in `ap-southeast-1`.
  - Two public subnets and two private application subnets across two Availability Zones.
  - Internet Gateway with public route tables (one per AZ).
  - Private route tables (one per AZ) with NAT Gateway default routes.
  - Two NAT Gateways (one per AZ) with dedicated Elastic IPs.
- **Load balancing**
  - Internet-facing Application Load Balancer across both public subnets.
  - HTTP listener on port 80.
  - Instance target group with health checks (`/health.html`, 30s interval, matcher 200).
  - Both EC2 instances registered as targets.
- **Compute**
  - Two private EC2 instances (`server1`, `server2`) using Amazon Linux 2023 (AMI resolved via SSM parameter).
  - No public IPs; encrypted gp3 root volumes; IMDSv2 enforced.
  - Instance type configurable via `instance_type` variable (default `t3.micro`).
  - Optional existing key pair for admin use.
- **IAM**
  - EC2 instance role with `AmazonSSMManagedInstanceCore` for SSM Session Manager.
  - Instance profile and role policy attachment.
- **SSM**
  - Optional VPC interface endpoints (`ssm`, `ssmmessages`, `ec2messages`) for private-only management, enabled by default.
- **Web servers**
  - `user-data/server1.sh` serves **"Hello from server1"**.
  - `user-data/server2.sh` serves **"Hello from server2"**.
  - Httpd auto-started on boot via cloud-init; `/health.html` endpoint for ALB health checks.
- **Docs**
  - `README.md`, `ARCHITECTURE.md`, `CHANGELOG.md`.
- **Ops**
  - `terraform.tfvars.example`, `.gitignore`, pinned provider `~> 6.0`, pinned Terraform `>= 1.5`.

### Applied (2026-08-08)

- `terraform apply` executed: **44 resources created**, 0 changed, 0 destroyed.
- Deployed VPC (`vpc-01f41ae7000998089`), ALB, 2 NAT Gateways, and two EC2 instances.
- ALB verified serving both `server1` and `server2` responses (round-robin) and `/health.html` returning 200.