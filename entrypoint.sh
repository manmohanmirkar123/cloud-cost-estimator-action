#!/bin/bash

set -euo pipefail

# Required env vars from action.yml
: "${IAC_PATH:=.}"
: "${PROVIDER:=aws}"
: "${GITHUB_OUTPUT:=/github/output}"
: "${INFRACOST_API_KEY:?INFRACOST_API_KEY must be set}"

LOCAL_BIN_DIR="${RUNNER_TEMP:-/tmp}/cloud-cost-estimator-bin"
mkdir -p "$LOCAL_BIN_DIR"
export PATH="$LOCAL_BIN_DIR:$PATH"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$LOCAL_BIN_DIR" >> "$GITHUB_PATH"
fi

download_file() {
  local url="$1"
  local output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$output"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$output"
  else
    echo "::error::Neither curl nor wget is available to download dependencies."
    exit 1
  fi
}

install_jq() {
  local jq_arch
  case "$(uname -m)" in
    x86_64) jq_arch="amd64" ;;
    aarch64|arm64) jq_arch="arm64" ;;
    *)
      echo "::error::Unsupported jq architecture: $(uname -m)"
      exit 1
      ;;
  esac

  download_file \
    "https://github.com/jqlang/jq/releases/latest/download/jq-linux-${jq_arch}" \
    "$LOCAL_BIN_DIR/jq"
  chmod +x "$LOCAL_BIN_DIR/jq"
}

echo "::group::Setup Dependencies"
# Composite actions run as the workflow user, so install any missing tools into
# a writable temp directory instead of using apt or system paths.
if ! command -v jq >/dev/null 2>&1; then
  install_jq
fi

# Install Terraform from the official release zip so it works across runner images.
if ! command -v terraform &> /dev/null; then
  terraform_arch="$(uname -m)"
  case "$terraform_arch" in
    x86_64) terraform_arch="amd64" ;;
    aarch64|arm64) terraform_arch="arm64" ;;
    *)
      echo "::error::Unsupported Terraform architecture: $terraform_arch"
      exit 1
      ;;
  esac

  terraform_version="$(
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version'
    elif command -v wget >/dev/null 2>&1; then
      wget -qO- https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version'
    else
      echo "::error::Neither curl nor wget is available to download Terraform."
      exit 1
    fi
  )"
  download_file "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_${terraform_arch}.zip" \
    "terraform_${terraform_version}_linux_${terraform_arch}.zip"
  unzip -q "terraform_${terraform_version}_linux_${terraform_arch}.zip"
  install -m 0755 terraform "$LOCAL_BIN_DIR/terraform"
  rm -f terraform
  rm -f "terraform_${terraform_version}_linux_${terraform_arch}.zip"
fi

# Install Infracost latest release
if ! command -v infracost &> /dev/null; then
  infracost_arch="$(uname -m)"
  case "$infracost_arch" in
    x86_64) infracost_arch="amd64" ;;
    aarch64|arm64) infracost_arch="arm64" ;;
    *)
      echo "::error::Unsupported Infracost architecture: $infracost_arch"
      exit 1
      ;;
  esac

  tmp_dir="$(mktemp -d)"
  download_file "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-${infracost_arch}.tar.gz" \
    "infracost-linux-${infracost_arch}.tar.gz"
  tar -xzf "infracost-linux-${infracost_arch}.tar.gz" -C "$tmp_dir"
  infracost_bin="$(find "$tmp_dir" -type f \( -name infracost -o -name 'infracost-*' \) | head -n 1)"
  if [ -z "$infracost_bin" ]; then
    echo "::error::Infracost binary not found after extract"
    rm -rf "$tmp_dir"
    exit 1
  fi
  install -m 0755 "$infracost_bin" "$LOCAL_BIN_DIR/infracost"
  rm -f "infracost-linux-${infracost_arch}.tar.gz"
  rm -rf "$tmp_dir"
fi
echo "::endgroup::"

echo "::group::Cloud Cost Estimation"
echo "Provider: $PROVIDER"
echo "IaC path: $IAC_PATH"

# Ensure dir exists and has IaC
IAC_DIR="${GITHUB_WORKSPACE:-.}/$IAC_PATH"
echo "Changing to dir: $IAC_DIR"
cd "$IAC_DIR" || { echo "::error::IaC directory not found: $IAC_DIR"; exit 1; }
echo "Current dir: $(pwd)"
echo "Files: $(ls -la)"

if ! find . -maxdepth 2 \( -name "*.tf" -o -name "*.tfvars" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) | grep -q .; then
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
infracost breakdown \
  --config-file infracost.hcl \
  --format json \
  --out-file report.json

# Readable report
report_file="$(pwd)/report.txt"
json_report_file="$(pwd)/report.json"
infracost output --path report.json --format table --out-file "$report_file" || cp report.json "$report_file"

# Parse JSON
total_cost=$(jq -r '
  if .totalMonthlyCost then
    .totalMonthlyCost
  elif .diffTotalMonthlyCost then
    .diffTotalMonthlyCost
  else
    ([.projects[]? | (.breakdown.totalMonthlyCost // .diff.totalMonthlyCost // "0") | tonumber] | add | tostring)
  end
' report.json)
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
  echo "report=$report_file"
  echo "report-json=$json_report_file"
} >> "$GITHUB_OUTPUT"

echo "::endgroup::"
echo "✅ Total monthly cost: \$${total_cost}"
