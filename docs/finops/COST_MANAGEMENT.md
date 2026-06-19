# CloudMart Cost Management and FinOps

## Controls implemented

- Every Terraform environment applies `Project`, `Environment`, `Team`, and `Owner` tags through provider default tags.
- AWS Budgets creates an environment-specific monthly cost budget.
- A forecasted notification is sent at 80% of the threshold.
- An actual-cost notification is sent at 100% of the threshold.
- ECR retains only the latest 10 images per repository.
- DynamoDB uses on-demand capacity.
- Staging uses a single-AZ RDS database; production uses Multi-AZ.
- Velero backup objects expire automatically after 30 days. The production backup bucket
  stores backups for both namespaces to avoid assigning two IAM roles to one Velero service account.

Before applying Terraform, replace the example owner and notification email addresses in
`infra/environments/<environment>/terraform.tfvars`.

## Produce the required cost report

Cost Explorer must be enabled in the AWS account. Run:

```bash
bash scripts/aws-cost-report.sh 30
```

The command creates:

- `evidence/cost/daily-cost-by-service.json`
- `evidence/cost/cloudmart-cost-by-environment.json`

For the report and demonstration, also capture AWS Cost Explorer screenshots showing:

1. Daily unblended cost grouped by service.
2. A filter for `Project=cloudmart`.
3. Cost grouped by the `Environment` cost-allocation tag.
4. The active AWS Budget and its subscribed email address.

AWS cost-allocation tags must be activated in Billing before Cost Explorer can group by them.

## Unit economics: cost per 1,000 orders

Use the same period for both cost and order count:

```text
cost_per_1000_orders = cloudmart_cost_usd / successful_orders * 1000
```

Example worksheet:

| Input | Value |
|---|---:|
| CloudMart infrastructure cost for period | Replace with Cost Explorer total |
| Successful orders in period | Replace with application metric or database count |
| Cost per 1,000 orders | `(cost / orders) * 1000` |

Do not include failed or cancelled test orders unless the report explicitly states that choice.

## Compute Optimizer review

After at least 14 days of metrics, review AWS Compute Optimizer recommendations for the EKS
worker instances. Record each recommendation in the report:

| Resource | Recommendation | Accept/reject | Reason |
|---|---|---|---|
| EKS production nodes | Capture from AWS | Pending | Compare CPU, memory, availability and disruption risk |
| EKS staging nodes | Capture from AWS | Pending | Prefer lower cost when performance remains adequate |

## One-year commitment analysis

Use the AWS Pricing Calculator or Cost Explorer Savings Plans recommendations. Record:

```text
annual_on_demand_cost = monthly_node_cost * 12
annual_committed_cost = quoted_hourly_commitment * 24 * 365
annual_saving = annual_on_demand_cost - annual_committed_cost
saving_percent = annual_saving / annual_on_demand_cost * 100
```

Only recommend a commitment for the stable production baseline. Keep burst and staging
capacity on demand or Spot so the team does not commit to unused capacity.

## Evidence checklist

- [ ] Budget subscription email confirmed.
- [ ] Daily cost-by-service screenshot captured.
- [ ] `Project` and `Environment` cost-allocation tags activated.
- [ ] Unit economics calculated with an actual order count.
- [ ] Compute Optimizer recommendations recorded.
- [ ] One-year Savings Plan comparison recorded.
