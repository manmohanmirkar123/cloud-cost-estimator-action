#!/bin/bash

set -euo pipefail

# Required env vars from action.yml
: "${IAC_PATH:=.}"
: "${PROVIDER:=aws}"
: "${GITHUB_OUTPUT:=/github/output}"

echo "::group::Cloud Cost Estimation"
echo "Provider: $PROVIDER"
echo "IaC path: $IAC_PATH"

# Ensure dir exists and has IaC
cd "$GITHUB_WORKSPACE/$IAC_PATH"
if ! ls *.tf *.tfvars *.json *.yaml *.yml 1> /dev/null 2>&1; then
  echo "::error::No IaC files found"
  exit 1
fi

# Create Infracost config
cat > infracost.hcl << EOF
version = "0.1"
[aws]
  currency_code = "USD"
[azure]
  currency_code = "USD"
[gcp]
  currency_code = "USD"

projects = [
  {
    name = "iac-project"
    path = "."
  }
]
EOF

# Export API key if provided
if [ -n "${INFRACOST_API_KEY:-}" ]; then
  export INFRACOST_API_KEY
fi

# Terraform init if .tf files
if ls *.tf >/dev/null 2>&1; then
  terraform init -backend=false || true
fi

# Estimate
infracost estimate \\
  --project-id test \\
  --config-file infracost.hcl \\
  --format json \\
  --out-file report.json

# HTML report
infracost report --config-file infracost.hcl --out-file report.html || true

# Parse JSON
total_cost=$(jq -r '.totalMonthlyCost | tonumber // empty' report.json)
breakdown=$(jq -c . report.json)

if [ -z "$total_cost" ]; then
  total_cost="unknown"
fi

# Set outputs
{
  echo "total-monthly-cost=$total_cost"
  echo "breakdown<<JSON"
  echo "$breakdown"
  echo "JSON"
  echo "report=report.html"
} >> "$GITHUB_OUTPUT"

echo "::endgroup::"
echo "✅ Total monthly cost: \$${total_cost}"

