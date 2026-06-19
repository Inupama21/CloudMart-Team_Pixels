# CloudMart Disaster Recovery Plan

## Recovery objectives

| Component | RPO | RTO | Business justification |
|---|---:|---:|---|
| User data in RDS PostgreSQL | 5 minutes | 60 minutes | Registration and profile data must not suffer material loss |
| Product catalogue in DynamoDB | 5 minutes | 30 minutes | Catalogue availability directly affects sales |
| Kubernetes resources | 24 hours from Velero, near-zero from Git | 30 minutes | Git is the source of truth; Velero provides an independent cluster backup |
| Order events in SQS | Queue retention window | 30 minutes | Durable queued events can be replayed after service recovery |
| Complete CloudMart platform | 5 minutes for managed data | 90 minutes | Includes database restore, cluster deployment and smoke tests |

## Implemented protections

- Production RDS is Multi-AZ.
- RDS automated backups and point-in-time recovery are retained for seven days.
- Production RDS has deletion protection and requires a final snapshot on deletion.
- RDS and DynamoDB use a customer-managed KMS key with annual key rotation.
- DynamoDB point-in-time recovery is enabled.
- SQS uses server-side encryption and a dead-letter queue.
- Terraform state is versioned and stored remotely with locking.
- Velero receives a private, encrypted, versioned S3 bucket and least-privilege IRSA role.
- Daily Velero schedules cover both CloudMart namespaces.
- A script exports non-sensitive Kubernetes resources for storage in Git.

## Install Velero

Deploy the production Terraform environment and obtain:

```bash
terraform output -raw velero_bucket_name
terraform output -raw velero_role_arn
```

Install Velero with the AWS plugin:

```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

helm upgrade --install velero vmware-tanzu/velero \
  --namespace velero \
  --create-namespace \
  --set configuration.backupStorageLocation[0].name=default \
  --set configuration.backupStorageLocation[0].provider=aws \
  --set configuration.backupStorageLocation[0].bucket=<VELERO_BUCKET> \
  --set configuration.backupStorageLocation[0].config.region=us-east-1 \
  --set serviceAccount.server.annotations."eks\.amazonaws\.com/role-arn"=<VELERO_ROLE_ARN> \
  --set credentials.useSecret=false \
  --set initContainers[0].name=velero-plugin-for-aws \
  --set initContainers[0].image=velero/velero-plugin-for-aws:v1.10.1 \
  --set initContainers[0].volumeMounts[0].mountPath=/target \
  --set initContainers[0].volumeMounts[0].name=plugins
```

Apply the schedules:

```bash
kubectl apply -f k8s/dr/velero-schedules.yaml
velero schedule get
```

## Kubernetes manifest backup to Git

Run after every material deployment and before the demonstration:

```bash
bash scripts/export-k8s-manifests.sh cloudmart-prod
git add backups/k8s/cloudmart-prod
git commit -m "chore: refresh production Kubernetes backup"
```

The script deliberately excludes Kubernetes Secret values.

## RDS point-in-time recovery test

Never restore over production. Restore to a temporary test instance:

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier cloudmart-users-db-production \
  --target-db-instance-identifier cloudmart-users-db-production-restore-test \
  --use-latest-restorable-time \
  --db-subnet-group-name cloudmart-rds-subnet-group-production \
  --no-publicly-accessible
```

Then:

1. Wait until the test instance is `available`.
2. Attach the same restricted database security group if it was not inherited.
3. Start a temporary pod in `cloudmart-prod`.
4. Connect with SSL and verify the `users` table and expected row count.
5. Capture screenshots/terminal evidence.
6. Delete the temporary instance after evidence is collected.

## DynamoDB recovery test

```bash
aws dynamodb restore-table-to-point-in-time \
  --source-table-name cloudmart-products-production \
  --target-table-name cloudmart-products-restore-test \
  --use-latest-restorable-time
```

Verify a sample product, capture evidence, then delete the temporary table.

## Velero restore test

```bash
velero backup create cloudmart-prod-manual-test \
  --include-namespaces cloudmart-prod \
  --wait

velero backup describe cloudmart-prod-manual-test --details

velero restore create cloudmart-prod-restore-test \
  --from-backup cloudmart-prod-manual-test \
  --namespace-mappings cloudmart-prod:cloudmart-dr-test \
  --wait

kubectl get all -n cloudmart-dr-test
```

Run smoke tests in the isolated namespace, capture evidence, and delete the restore:

```bash
velero restore delete cloudmart-prod-restore-test --confirm
kubectl delete namespace cloudmart-dr-test
```

## Recovery sequence

1. Declare the incident and stop deployments.
2. Identify the last known-good recovery point.
3. Restore RDS and/or DynamoDB to temporary recovery resources.
4. Update Secrets Manager/configuration with restored endpoints.
5. Recreate the cluster infrastructure using Terraform if necessary.
6. Restore Kubernetes resources from Git or Velero.
7. Run health checks and an end-to-end test order.
8. Resume traffic only after data and application verification.
9. Record actual RTO, actual RPO and lessons learned.

## Required live evidence

- [ ] RDS automated backups show seven-day retention.
- [ ] Production RDS shows Multi-AZ enabled.
- [ ] Latest restorable time is visible.
- [ ] Temporary RDS restore completed and was queried successfully.
- [ ] DynamoDB PITR is enabled.
- [ ] Velero backup and test-namespace restore succeeded.
- [ ] Actual recovery duration is recorded.
