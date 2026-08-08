# aws-tfm — Production-Style AWS Web Infrastructure (Terraform)

![Terraform License](https://img.shields.io/badge/terraform-1.20%2B-blueviolet)
![AWS Provider](https://img.shields.io/badge/aws-%3E%3D%206.0-orange)

Terraform project that provisions a **production-style, highly available web application architecture** in the Singapore region (`ap-southeast-1`) across two Availability Zones. The stack uses a internet-facing Application Load Balancer (ALB) in public subnets, two private EC2 web servers behind it, and one NAT Gateway per subnets for outbound internet access.

> **Important:** This project is intentionally self-contained under `terraform/` and does **not** touch unrelated files at the repository root.

---

## Table of contents

1. [Architecture overview](#1-architecture-overview)
2. [Architecture diagram (Mermaid)](#2-architecture-diagram-mermaid)
3. [AWS region and AZ design](#3-aws-region-and-az-design)
4. [VPC CIDR design](#4-vpc-cidr-design)
5. [Public subnet design](#5-public-subnet-design)
6. [Private subnet design](#6-private-subnet-design)
7. [NAT Gateway design](#7-nat-gateway-design)
8. [Internet Gateway](#8-internet-gateway)
9. [Route tables](#9-route-tables)
10. [ALB architecture](#10-alb-architecture)
11. [EC2 architecture](#11-ec2-architecture)
12. [Security-group flow](#12-security-group-flow)
13. [SSH/SSM access design](#13-ssm-ssm-access-design)
14. [Server1/server2 behavior](#14-server1server2-behavior)
15. [Health checks](#15-health-checks)
16. [High-availability considerations](#16-high-availability-considerations)
17. [Terraform project structure](#17-terraform-project-structure)
18. [Prerequisites](#18-prerequisites)
19. [AWS authentication requirements](#19-aws-authentication-requirements)
20. [Terraform installation](#20-terraform-installation)
21. [Terraform initialization](#21-terraform-initialization)
22. [Terraform validation](#22-terraform-validation)
23. [Terraform plan](#23-terraform-plan)
24. [Terraform apply instructions](#24-terraform-apply-instructions)
25. [How to test the ALB after deployment](#25-how-to-test-the-alb-after-deployment)
26. [Expected responses](#26-expected-responses)
27. [Troubleshooting](#27-troubleshooting)
28. [Cost considerations](#28-cost-considerations)
29. [Security considerations](#29-security-considerations)
30. [Cleanup / destroy instructions](#30-cleanup--destroy-instructions)

---

## 1. Architecture overview

The design follows AWS Well-Architected best practices for a small, internet-facing web application:

- A dedicated VPC (`10.20.0.0/17`) spans **two Availability Zones** (`ap-southeast-1a`, `ap-southeast-1b`).
- **Public route subnets** host the ALB and the NAT Gateways — the only resources reachable in the gateways.
- **Private application subnets** host the EC2 web servers (`server1`, `server2`). They have **no public IPs** and are not directly reachable from the internet.
- The **ALB** is internet-facing, listens on HTTP/80 and forwards traffic round-robin to both instances.
- Each AZ has its own **NAT Gateway** so private instances can reach the internet (e.g. package updates, SSM) while remaining unreachable inbound.
- Traffic flow: `Internet → ALB (public subnet) → EC2 (private subnet)`. No EC2 instance is ever exposed publicly.

Key security group flow: ALB allows TCP/80 from `0.0.0.0/0` and only routes to instance private IPs; web SG allows HTTP from the ALB SG, and SSH is not exposed at the ingress. Management is via SSM.

## 2. Architecture diagram (Mermaid)

```mermaid
flowchart TD
    User[Internet Users]
    ALB_DNS[ALB DNS Name]
    User --> ALB_DNS
    User -. HTTP :80 .-> ALB{{Application<br/>Load Balancer<br/>ap-southeast-1}}
    ALB --> ALBSG[ALB Security Group<br/>Inbound TCP 80 0.0.0.0/0]

    subgraph VPC[VPC 10.0.0.0/17]
        subgraph PublicSubnets[Public Subnets]
            NATGW1[NAT Gateway AZ-a]
            NATGW2[NAT Gateway AZ-b]
            ALB[ALB<br/>Internet-facing<br/>HTTP 80]
        end

        subgraph PrivateSubnets[Private Subnets]
            EC21[EC2 server1<br/>10.0.21.x]
            EC22[EC2 server2<br/>10.0.22.x]
        end

        IGW[IGW]

        ALBSG --"TCP 80"--> EC21
        ALBSG --"TCP 80"--> EC22

        EC21 --> NATGW1
        EC22 --> NATGW2
        NATGW1 --> IGW
        NATGW2 --> IGW
    end

    ALB --- IGW
    NATGW1 --- IGW
    NATGW2 --- IGW
```
```

> A full, detailed architecture with resource-level detail is available in [ARCHITECTURE.md](ARCHITECTURE.md).

## 3. AWS region and AZ design

- **Region:** `ap-southeast-1` (Singapore).
- **AZs:** `ap-southeast-1`a` and `ap-southeast-1b` (two of the three AZs in the region).

## 4. VPC CIDR design

- VPC CIDR: **`10.0.0.0/17`**.
- Enabled features: `enable_dns_hostnames = true` and `enable_dns_support = true`.
- Subnet CIDRs are derived from the VPC CIDR via `cidrsubnet()`:

| Purpose | CIDR | AZ |
|---|---|---|
| Public subnet 1 | `10.0.1.0/24` | ap-southeast-1a |
| Public subnet 2 | `10.0.2.0/24` | ap-southeast-1b |
| Private app subnet 1 | `10.0.21.0/24` | ap-southeast-1a |
| Private app subnet 2 | `10.0.22.0/24` | ap-southeast-1b |

## 5. Public subnet design

- Two public subnets in different AZs (`10.0.1.0/24` and `10.0.2.0/24`).
- `map_public_ip_on_launch = true`.
- Only the ALB and NAT Gateways are deployed in the public subnets. **EC2 is in the private subnets.**

## 6. Private subnet design

- Two private subnets in different AZs (`10.0.21.0/24` and `10.0.22.0/24`).
- No `map_public_ip_on_launch`; instances get private IPs only.

## 7. NAT Gateway design

- One NAT Gateway per AZ for high availability.
- One Elastic IP per NAT Gateway.
- Each NAT GW is placed in the public subnet of the *same* AZ.

## 8. Internet Gateway

- A single `aws_internet_gateway` attached to the VPC.
- Provides the default gateway for the public route tables.
- Requires the IGW to be created before the NAT GWs (["depends_on"]).

## 9. Route tables

| Route table | Target | Used for |
|---|---|---|
| `route public` | `0.0.0.0/0` → IGW (via IGW) | public subnet(s) |
| `route private` | `0.0.0.0/0` → NAT GW | private subnet(s) |

## 10. ALB architecture

- Internet-facing ALB (`internal = false`).
- Listener: HTTP:80.
- Target group: `instance` type with health check on `/health.html`.
- Both instances registered in the target;
- Reduces to 2 targets — the ALB evenly distributes with health

## 11. EC2 architecture

- **Two EC2 instances** (`t3.micro` default) named `server1` and `server2`.
- Launched in private subnets, no public IP.
- Amazon Linux 3 AMI (SSM parameter resolves the latest x86_64).
- Uses encrypted EBS root (gp3) volumes.
- Fully IAM instance profile for SSM access.

## 12. IAM & SSM access

- An IAM instance profile gives the EC2 instances permission for `AmazonSSMManagedInstanceCore`.
- `terraform init` generated the managed instance core
- Recommended way: SSM Session Manager (`aws ssm start-session --target <instance>`)

The EC2 SG only allows HTTP traffic from the ALB SG or from the lock; Port 22 not opened / only via SSM **not open to the internet**.

## 13. Insecure secrets handling

The unsecure open SSM port is not enabled; no data is stored on instance.

## 14. Server1 / server2 behavior

| Server | Response |
|---|---|
| server1 | `"Hello from server1"` |
| server2 | `"Hello from server2"` |

The two servers run `httpd` with a simple `<!--sidecar . */ -->`.

## 15. Health checks

- Target group health check:
  - Path: `/health.html`
  - Interval: `timeout` 5s
  - Residential threshold: 2
  - Matcher: `200`.
Use `/health.html` from each host after boot.

## 16. High-availability considerations

- Two instances in two AZs — those water service can survive an AZ loss.
- ALB appears health via the target group and route to healthy targets.

**Remaining single points of failure / limitations:**

- No ASG — a fix count of two instances.
- Native auto-healing (self-healing) via ASGF not configured.
- Region-level outage still down entire region (no DR).
- Single ALB per region.
- No database or stateful component in this repo.

## 17. Terraform project structure

```
terraform/
├── versions.tf          # Terraform += 1.5, AWS provider ~> 6.0
├── provider.tf         # AWS provider + common tags
├── variables.tf        # All environment-dependant values
├── locals.tf           # CIDR
├── networking.tf        # VPC, subnets, IGW, route tables
├── security.tf         # Security groups
├── nat.tf              # NAT Gateways
├── iam.tf              # IAM role for SSM
├── alb.tf              # ALB, listener, target group
├── ec2.tf              # web servers
├── outputs.tf
├── user-data/
│   ├── server1.sh
│   └── server2.sh
├── .gitignore
├── terraform.tfvars.example
├── ARCHITECTURE.md
├── CHANGELOG.md
└── README.md
```

## 18. Prerequisites

- Terraform >= 1.5 installed. AWS CLI. Admin IAM access.
- The account should have access to create resources.

## 20. Terraform initialization

```bash
terraform init
```

## 21. Terraform validation

```bash
tfenv install 1.15.8
tfenv use 1.15.8
terraform fmt -recursive
terraform validate
```

## 22. Terraform plan

```bash
terraform plan -out=tfplan
```

## 23. Terraform apply instructions

> **Note:** `apply` was intentionally **NOT performed**.

```bash	erraform apply terraform.tfplan   # optional -auto-approve
```

## 27. Troubleshooting

| Scenario | Likely cause |
|---|---|
| EC2 unreachable | Check the SSH key, the AMI user, the security group rules |
| ALB returns 503 | Verify health check path + that httpd is running |
| Terraform apply timeout | NAT can't resolve internet (IGW/route) or insufficient arguments |
| AWS EC2's request | IAM permissions or endpoint needed |

## 29. Cost considerations

- 2 × t3.micro — about ~$22/month
- **2 × NAT Gateway — around ~$84/month (dominant)**/ (-t2micro)
- 2 × Elastic IP — free when attached
- ALB — ~$0.025/hr (base)

## 30. Cleanup / terminate

```bash
terraform destroy -auto-approve
```

> Removes everything created by the `apply`. Ensure you have a backup of state and any data before destroy.

__Full, up-to-date instructions are in `Architecture.md`/docs._
