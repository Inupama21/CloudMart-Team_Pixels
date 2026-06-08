# CloudMart – Infrastructure (Terraform)

This directory contains all Terraform code for provisioning CloudMart's AWS infrastructure.

## Directory Structure

```
infra/
├── .gitignore                          # Prevents secrets & state from being committed
├── bootstrap/                          # Run ONCE by team lead to create remote state
│   ├── main.tf                         # S3 bucket + DynamoDB lock table
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example        # Copy → terraform.tfvars, fill values
│
├── modules/                            # Reusable, environment-agnostic modules
│   ├── networking/                     # VPC, subnets, IGW, NAT, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/                            # EKS cluster, node groups, OIDC (IRSA)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/                       # RDS PostgreSQL + DynamoDB
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── messaging/                      # SQS orders queue + DLQ
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecr/                            # ECR repos for all 5 services
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── enviornments/
    ├── staging/                        # Staging: SPOT nodes, single-AZ DB, smaller sizes
    │   ├── backend.tf                  # Remote state config (S3 key: staging/)
    │   ├── main.tf                     # Composes all modules
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    └── production/                     # Production: ON_DEMAND, multi-AZ, 3 AZs
        ├── backend.tf                  # Remote state config (S3 key: production/)
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
```

---

## Quick-Start Guide

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | ≥ 1.7 | https://developer.hashicorp.com/terraform/install |
| AWS CLI | ≥ 2 | https://aws.amazon.com/cli/ |
| kubectl | ≥ 1.28 | https://kubernetes.io/docs/tasks/tools/ |

### Step 1 – Bootstrap (team lead, run once)

> Only one person does this. Everyone else skips to Step 2.

```bash
cd infra/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set your AWS account ID in state_bucket_name
terraform init
terraform apply
# Note the outputs – paste bucket name into enviornments/*/backend.tf
```

### Step 2 – Configure your environment

```bash
# For staging:
cd infra/enviornments/staging
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your DB credentials
```

### Step 3 – Initialise & plan

```bash
terraform init    # Downloads providers, connects to remote state
terraform plan    # Preview changes (no cost yet)
```

### Step 4 – Apply

```bash
terraform apply   # Type 'yes' to confirm
```

### Step 5 – Update kubeconfig

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name $(terraform output -raw eks_cluster_name)
kubectl get nodes
```

---

## Working in a Team Without Conflicts

| Rule | Why |
|------|-----|
| **Never commit `terraform.tfvars`** | Contains passwords – use `.tfvars.example` as template |
| **Always `terraform plan` before `apply`** | Catch drift early |
| **State locking via DynamoDB** | Prevents two people running `apply` at the same time |
| **Separate state keys per environment** | `staging/terraform.tfstate` vs `production/terraform.tfstate` – no cross-contamination |
| **Use feature branches for infra changes** | PR review before merging to main |
| **Tag every resource** | `common_tags` applied globally via `provider default_tags` |

---

## Environment Differences

| Setting | Staging | Production |
|---------|---------|------------|
| Node capacity type | `SPOT` | `ON_DEMAND` |
| Node size | `t3.medium` | `t3.large` |
| AZs | 2 | 3 |
| RDS Multi-AZ | ❌ | ✅ |
| RDS instance | `db.t3.micro` | `db.t3.small` |
| RDS backup | 3 days | 14 days |
| EKS API endpoint | Public | Private |
| Deletion protection | ❌ | ✅ |

---

## Adding a New Module

1. Create `infra/modules/<name>/main.tf`, `variables.tf`, `outputs.tf`
2. Add a `module "<name>"` block in both `enviornments/staging/main.tf` and `enviornments/production/main.tf`
3. Expose relevant outputs in both environments

---

*IS 4630 Cloud Infrastructure Management | University of Moratuwa*
