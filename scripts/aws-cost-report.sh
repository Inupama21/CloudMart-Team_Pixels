#!/usr/bin/env bash
set -euo pipefail

days="${1:-30}"
output_dir="${2:-evidence/cost}"
end_date="$(date -u +%F)"
start_date="$(date -u -d "${days} days ago" +%F)"

mkdir -p "${output_dir}"

aws ce get-cost-and-usage \
  --time-period "Start=${start_date},End=${end_date}" \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  > "${output_dir}/daily-cost-by-service.json"

aws ce get-cost-and-usage \
  --time-period "Start=${start_date},End=${end_date}" \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"Project","Values":["cloudmart"]}}' \
  --group-by Type=TAG,Key=Environment \
  > "${output_dir}/cloudmart-cost-by-environment.json"

echo "Cost evidence written to ${output_dir}"

