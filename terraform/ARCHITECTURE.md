# Architecture — Production-Style AWS Web Infrastructure

This document is the deep-dive reference for the `aws-tfm` milestone in `ap-southeast-1` (Singapore).

---

## 1. Overview

A highly available, two-AZ web stack:

- **Ingress**: Internet -> Internet-facing ALB (public subnets, HTTP:80)
- **Compute**: 2× Amazon Linux 2023 EC2 in private subnets    (one per AZ)
- **Egress**: NAT Gateway per AZ
- **Management**: SSM Session Manager via IAM

The EC2 instances are private-only; the only internet entry point is the ALB.

## 2. Network flow

```mermaid
flowchart LR
    C[Client] -->|HTTP 80| DN[ALB DNS]
    DN --> ALB[ALB - public subnets]
    ALB -->|HTTP 80| A[server1 - private AZ-a]
    ALB -->|HTTP 80| B[server2 - private AZ-b]
    A -->|0.0.0.0/0 egress| N1[NAT AZ-a]
    B -->|0.0.0.0/0 egress| N2[NAT AZ-b]
    N1 --> IGW
    N2 --> IGW
```

## 3. Resource topology

```mermaid
graph TD
    V[VPC 10.0.0.0/17] --> PUBSUB1[Public subnet 10.0.1.0/24]
    V --> PUBSUB2[Public subnet 10.0.2.0/24]
    V --> PRISUB1[Private subnet 10.0.21.0/24]
    V --> PRISUB2[Private subnet 10.0.22.0/24]
    V --> IGW

    IGW --> IGW

    NAT1[NAT GW AZ-a] --> PRIVRT1[private route table]
    NAT2[NAT GW AZ-b] --> PRIVRT2

    ALB --> LIST[HTTP :80]
    LIST --> TG[target group web]
    TG --> i1[server1]
    TG --> i2[server2]

    SGALB[alb-sg] --> ALB
    SGB[elt web-sg] --> A
    SGB --> B
```

## 4. Availability model

- AZ resilience for compute.
- ALB health check on `/health.html`. Automatic failover.
- NAT = 2 in 2 AZs.
- No ASG. No auto-scaling.

## 5. Security model

- Inbound in ALB: 0.0.0.0/0 on 80.
- Instance SG: only source ALB SG + outbound to NAT.
- SSH not open to public internet.
- IAM least-privilege (SSM)
- NAToutbound for updates.

## 6. Ops model

- SSM Session Manager (no bastion).
- `terraform plan` in CI.

---

## Appendix

This architecture doc is appendally a gift from the drafted plan. The `plan` is **not applied**, only authored.
