#!/usr/bin/env bash
set -euo pipefail

namespace="${1:-cloudmart-prod}"
output_dir="${2:-backups/k8s/${namespace}}"

mkdir -p "${output_dir}"

kubectl get namespace "${namespace}" -o yaml > "${output_dir}/namespace.yaml"
kubectl get deployments,services,ingresses,configmaps,hpa,pdb,networkpolicies,serviceaccounts \
  -n "${namespace}" -o yaml > "${output_dir}/resources.yaml"

# Secret values are deliberately excluded. SecretProviderClass definitions are safe to export.
if kubectl api-resources --api-group=secrets-store.csi.x-k8s.io -o name | grep -q secretproviderclasses; then
  kubectl get secretproviderclasses -n "${namespace}" -o yaml \
    > "${output_dir}/secret-provider-classes.yaml"
fi

cat > "${output_dir}/metadata.txt" <<EOF
namespace=${namespace}
exported_at_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cluster=$(kubectl config current-context)
EOF

echo "Exported non-sensitive Kubernetes resources to ${output_dir}"
echo "Review the diff, then commit the backup to Git."

