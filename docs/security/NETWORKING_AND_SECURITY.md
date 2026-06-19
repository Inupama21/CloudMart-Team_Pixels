# CloudMart Networking and Security

## Implemented network architecture

The production VPC uses a `/16` CIDR across three availability zones. Every zone contains:

- A public subnet for the internet-facing ALB and NAT gateway.
- A private application subnet for EKS control-plane ENIs and worker nodes.
- An isolated data subnet for RDS PostgreSQL.

Application subnets route outbound internet traffic through one NAT gateway per zone. Data
subnets have no internet default route. DynamoDB uses a gateway VPC endpoint, while Secrets
Manager uses private interface endpoints with private DNS.

VPC flow logs capture accepted and rejected traffic in CloudWatch. Terraform also creates the
saved Logs Insights query `CloudMart/production/RejectedVpcTraffic`.

## Firewall justification

| Security group | Inbound | Outbound | Justification |
|---|---|---|---|
| ALB | TCP 80/443 from internet | Application subnet CIDRs only | Public entry point; no direct access to data subnets |
| EKS nodes | Self traffic; TCP 80/443 from ALB SG | Required application egress through NAT/endpoints | Supports pod communication and ALB targets without application AWS permissions on the node role |
| RDS | TCP 5432 from EKS node SG and bastion SG only | None | PostgreSQL is private and cannot be reached directly from the internet |
| VPC endpoints | TCP 443 from EKS node SG | VPC only | Keeps Secrets Manager traffic inside AWS networking |
| Bastion | No inbound by default; optional TCP 22 from explicit CIDRs | TCP 443 and PostgreSQL to data CIDRs | SSM Session Manager is the default administration path |

The EKS node IAM role contains only standard worker, CNI, ECR pull and SSM permissions. Data
access belongs to per-service IRSA roles.

## Workload identity

| Service account | Allowed AWS actions |
|---|---|
| product-service | CRUD on its DynamoDB products table |
| order-service | Send events to its SQS queue |
| notification-service | Receive/delete SQS events and send SES email |
| user-service | Read the environment application secret and decrypt its KMS key |

Production and staging use different IAM roles. The trust policies bind each role to the exact
namespace and Kubernetes service-account name.

## Secrets

Terraform creates:

```text
cloudmart/production/application
cloudmart/staging/application
```

The JSON secret contains the RDS host, port, database name, username, password, SSL mode and a
generated JWT signing key. The Secrets Store CSI Driver synchronises only the required values
into the namespace-local `cloudmart-secrets` Kubernetes Secret.

The old plaintext `k8s/secrets.yaml` file has been removed. Because it existed in Git history,
rotate the exposed RDS password and JWT secret before treating the environment as secure.

## Pod security and NetworkPolicies

Both namespaces enforce the Kubernetes `restricted` Pod Security Standard. Containers:

- Run as non-root.
- Disable privilege escalation.
- Drop all Linux capabilities.
- Use the runtime-default seccomp profile.

A default-deny ingress and egress policy is followed by explicit communication rules for:

- ALB to frontend.
- Frontend to product, order and user services.
- Order to product service.
- User service to PostgreSQL.
- Product, order and notification services to required AWS HTTPS endpoints.
- DNS over UDP and TCP.
- No inbound application traffic to notification-service.

## Deployment configuration

After production Terraform is applied, record:

```bash
terraform output -raw eks_oidc_provider_url
terraform output -raw alb_security_group_id
terraform output -raw waf_acl_arn
terraform output -raw application_secret_name
```

Configure these GitHub Actions repository variables:

```text
ACM_CERTIFICATE_ARN
WAF_ACL_ARN
ALB_SECURITY_GROUP_ID
```

`ACM_CERTIFICATE_ARN` must be an issued ACM certificate in the same AWS region. The workflow
installs the Secrets Store CSI Driver and AWS provider, applies service accounts, secret
integration and NetworkPolicies, then deploys the services.

Use the production `eks_oidc_provider_url` output as staging's `oidc_url` Terraform variable.
Also copy the production `vpc_id`, `private_route_table_ids`, and
`eks_node_security_group_id` outputs into staging's peering variables. Staging Terraform creates
same-account VPC peering and only routes the shared EKS application subnets to the staging VPC;
the staging database remains non-public.

## Bastion access

The bastion requires no SSH key when SSM is used:

```bash
aws ssm start-session --target "$(terraform output -raw bastion_instance_id)"
```

If SSH is required for a demonstration, add only the administrator's `/32` address to
`bastion_allowed_cidrs`. Never use `0.0.0.0/0`.

## Threat-detection evidence

GuardDuty is enabled by default in production. Generate a safe sample finding:

```bash
DETECTOR_ID="$(terraform output -raw guardduty_detector_id)"
aws guardduty create-sample-findings \
  --detector-id "${DETECTOR_ID}" \
  --finding-types UnauthorizedAccess:EC2/SSHBruteForce
```

Capture the finding and document the response: validate the source, isolate the affected
instance/security group, review CloudTrail and flow logs, rotate credentials, patch, and close
the finding after verification.
